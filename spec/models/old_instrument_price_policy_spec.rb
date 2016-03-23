require "rails_helper"

RSpec.describe OldInstrumentPricePolicy do

  it { is_expected.to allow_value(Date.current + 1).for(:start_date) }

  it { is_expected.to allow_value(Date.current - 1).for(:start_date) }

  it { is_expected.to allow_value(123.4567).for :usage_rate }

  it { is_expected.to allow_value(123.4567).for :usage_subsidy }

  context "test requiring instruments" do
    before(:each) do
      @facility         = create :facility
      @facility_account = create :facility_account, facility: @facility
      @price_group      = create :price_group, facility: @facility
      @instrument       = create :instrument, facility: @facility, facility_account: @facility_account
      @ipp = create :old_instrument_price_policy, price_group: @price_group, product: @instrument
    end

    it "should create using factory" do
      # price policy belongs to an instrument and a price group
      expect(@ipp).to be_valid
    end

    it "should return instrument" do
      # price policy belongs to an instrument and a price group
      expect(@ipp.product).to eq(@instrument)
    end

    it "should require usage or reservation rate, but not both" do
      @ipp.restrict_purchase = false

      expect(@ipp).to be_valid
      @ipp.reservation_rate = nil
      @ipp.usage_rate = nil
      expect(@ipp).not_to be_valid

      @ipp.usage_rate = 1
      expect(@ipp).to be_valid

      @ipp.usage_rate = nil
      @ipp.reservation_rate = 1
      expect(@ipp).to be_valid
    end

    it "should create a price policy for today if no active price policy already exists" do
      is_expected.to allow_value(Date.current).for(:start_date)
      @ipp.start_date = Date.current - 7.days
      @ipp.save validate: false
      ipp_new = create :old_instrument_price_policy, start_date: Date.current, price_group: @price_group, product: @instrument
      expect(ipp_new.errors_on(:start_date)).not_to be_nil
    end

    it "should not create a price policy for a day that a policy already exists for" do
      @ipp.start_date = Date.current + 7.days
      assert @ipp.save
      ipp_new = build :old_instrument_price_policy, start_date: Date.current + 7.days, price_group: @price_group, product: @instrument
      ipp_new.valid?
      expect(ipp_new.errors_on(:start_date)).not_to be_nil
    end

    describe "non overlapping policies" do
      before :each do
        @ipp.start_date = Date.current - 7.days
        @ipp.save validate: false
      end

      it "should return the date for the current policies" do
        create :old_instrument_price_policy, start_date: Date.current + 7.days, price_group: @price_group, product: @instrument
        expect(InstrumentPricePolicy.current_date(@instrument).to_date).to eq(@ipp.start_date.to_date)
        @ipp = create :old_instrument_price_policy, price_group: @price_group, product: @instrument
        expect(InstrumentPricePolicy.current_date(@instrument).to_date).to eq(@ipp.start_date.to_date)
      end

      it "should return the date for upcoming policies" do
        create :old_instrument_price_policy, start_date: Date.current, price_group: @price_group, product: @instrument
        ipp2 = create :old_instrument_price_policy, start_date: Date.current + 7.days, price_group: @price_group, product: @instrument
        ipp3 = create :old_instrument_price_policy, start_date: Date.current + 14.days, price_group: @price_group, product: @instrument
        expect(ipp2.class.next_date(@instrument).to_date).to eq ipp2.start_date.to_date
        next_dates = ipp2.class.next_dates @instrument
        expect(next_dates.size).to eq 2
        expect(next_dates).to include ipp2.start_date.to_date
        expect(next_dates).to include ipp3.start_date.to_date
      end
    end
  end

  # BASED ON THE MATH FUNCTION
  # duration_minutes = (end_time - start_time) / 60
  # cost = duration_minutes
  # TODO TK: finish explaining equation
  context "cost estimate tests" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
      @instrument       = FactoryGirl.create(:instrument,
                                             facility: @facility,
                                             reserve_interval: 30,
                                             facility_account: @facility_account)
      @price_group_product = FactoryGirl.create(:price_group_product, price_group: @price_group, product: @instrument)
      # create rule every day from 9 am to 5 pm, no discount, duration= 30 minutes
      @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    end

    it "should correctly estimate cost with usage cost" do
      pp = create :old_instrument_price_policy, ipp_attributes

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost with usage cost and subsidy" do
      pp = create :old_instrument_price_policy, ipp_attributes(usage_subsidy: 1.75)

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 4)
      expect(costs[:subsidy]).to eq(1.75 * 4)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3 * 4)
      expect(costs[:subsidy]).to eq(1.75 * 3 * 4)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3)
      expect(costs[:subsidy]).to eq(1.75 * 3)
    end

    it "should correctly estimate cost with usage cost and overage cost" do
      pp = create :old_instrument_price_policy, ipp_attributes(overage_rate: 15.50)

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost with reservation cost" do
      options = ipp_attributes(product: @instrument,
                               usage_rate: 0,
                               reservation_rate: 10.75)

      pp = create :old_instrument_price_policy, options

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost with reservation cost and subsidy" do
      options = ipp_attributes(product: @instrument,
                               usage_rate: 0,
                               reservation_rate: 10.75,
                               reservation_subsidy: 1.75)

      pp = create :old_instrument_price_policy, options

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 4)
      expect(costs[:subsidy]).to eq(1.75 * 4)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3 * 4)
      expect(costs[:subsidy]).to eq(1.75 * 3 * 4)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 3)
      expect(costs[:subsidy]).to eq(1.75 * 3)
    end

    it "should correctly estimate cost with usage and reservation cost" do
      options = ipp_attributes(product: @instrument,
                               usage_rate: 5,
                               reservation_rate: 5.75)

      pp = create :old_instrument_price_policy, options

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 4)
      expect(costs[:subsidy]).to eq(0)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 3 * 4)
      expect(costs[:subsidy]).to eq(0)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 3)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost with usage and reservation cost and subsidy" do
      options = ipp_attributes(product: @instrument,
                               usage_rate: 5,
                               usage_subsidy: 0.5,
                               reservation_rate: 5.75,
                               reservation_subsidy: 0.75)

      pp = create :old_instrument_price_policy, options

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 9:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 4)
      expect(costs[:subsidy]).to eq((0.5 + 0.75) * 4)

      # 3 hours (4 * 3 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 13:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 3 * 4)
      expect(costs[:subsidy]).to eq((0.5 + 0.75) * 3 * 4)

      # 35 minutes ceil(35.0/15.0) intervals (3)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 10:35")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((5 + 5.75) * 3)
      expect(costs[:subsidy]).to eq((0.5 + 0.75) * 3)
    end

    it "should correctly estimate cost across schedule rules" do
      # create adjacent schedule rule
      @instrument.update_attribute :reserve_interval, 30
      @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: @rule.end_hour, end_hour: @rule.end_hour + 1))
      pp = create :old_instrument_price_policy, ipp_attributes

      # 2 hour (8 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} #{@rule.end_hour - 1}:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} #{@rule.end_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 8)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost for a schedule rule with a discount" do
      # create discount schedule rule
      @instrument.update_attribute :reserve_interval, 30
      @discount_rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: @rule.end_hour, end_hour: @rule.end_hour + 1, discount_percent: 50))
      pp = create :old_instrument_price_policy, ipp_attributes

      # 1 hour (4 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} #{@discount_rule.start_hour}:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} #{@discount_rule.start_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 0.5 * 4)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate cost across schedule rules with discounts" do
      # create discount schedule rule
      @instrument.update_attribute :reserve_interval, 30
      @discount_rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, start_hour: @rule.end_hour, end_hour: @rule.end_hour + 1, discount_percent: 50))
      pp = create :old_instrument_price_policy, ipp_attributes

      # 2 hour (8 intervals); half of the time, 50% discount
      start_dt = Time.zone.parse("#{Date.current + 1.day} #{@rule.end_hour - 1}:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} #{@rule.end_hour + 1}:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq((10.75 * 0.5 * 4) + (10.75 * 4))
      expect(costs[:subsidy]).to eq(0)
    end

    it "should return nil if the end time is earlier than the start time" do
      pp = create :old_instrument_price_policy, ipp_attributes
      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 9:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs).to be_nil
    end

    it "should return nil for cost if purchase is restricted" do
      options = {
        start_date: Date.current,
        expire_date: Date.current + 7.days,
        price_group: @price_group,
        product: @instrument,
      }

      @price_group_product.destroy
      pp = create :old_instrument_price_policy, options

      start_dt = Time.zone.parse("#{Date.current + 1.day} 10:00")
      end_dt   = Time.zone.parse("#{Date.current + 1.day} 9:00")
      costs    = pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs).to be_nil
    end
  end

  context "cost estimate tests with all day schedule rules" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create!(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create!(FactoryGirl.attributes_for(:price_group))
      @instrument       = FactoryGirl.create(:instrument,
                                             facility: @facility,
                                             reserve_interval: 30,
                                             facility_account: @facility_account)
      @price_group_product = FactoryGirl.create(:price_group_product, price_group: @price_group, product: @instrument)
      @rule = @instrument.schedule_rules.create!(FactoryGirl.attributes_for(:schedule_rule, start_hour: 0, end_hour: 24))
      @pp = create :old_instrument_price_policy, ipp_attributes
    end

    it "should correctly estimate cost across multiple days" do
      # 2 hour (8 intervals)
      start_dt = Time.zone.parse("#{Date.current + 1.day} 23:00")
      end_dt   = Time.zone.parse("#{Date.current + 2.days} 1:00")
      costs    = @pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 8)
      expect(costs[:subsidy]).to eq(0)
    end

    it "should correctly estimate costs across time changes" do
      # 4 hours (16 intervals) accounting for 1 hour DST time change
      start_dt = Time.zone.parse("7 November 2010 1:00")
      end_dt   = Time.zone.parse("7 November 2010 4:00")
      costs    = @pp.estimate_cost_and_subsidy(start_dt, end_dt)
      expect(costs[:cost]).to    eq(10.75 * 16)
      expect(costs[:subsidy]).to eq(0)
    end
  end

  def ipp_attributes(overrides = {})
    attrs = {
      start_date: Date.current,
      expire_date: Date.current + 7.days,
      usage_rate: 10.75,
      usage_subsidy: 0,
      usage_mins: 15,
      reservation_rate: 0,
      reservation_subsidy: 0,
      reservation_mins: 15,
      overage_rate: 0,
      overage_subsidy: 0,
      overage_mins: 15,
      minimum_cost: nil,
      cancellation_cost: nil,
      price_group: @price_group,
      can_purchase: true,
      product: @instrument,
    }

    attrs.merge(overrides)
  end

  context "actual cost calculation tests" do
    before :each do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
      @instrument       = FactoryGirl.create(:instrument, facility_account: @facility_account, facility: @facility)
      @ipp = create :old_instrument_price_policy, ipp_attributes(
        usage_rate: 100,
        usage_subsidy: 99,
        usage_mins: 15,
        overage_rate: nil,
        overage_subsidy: nil,
        reservation_rate: 0,
      )
      @now = Time.zone.now
      # set reservation window to usage minutes from the price policy
      @reservation = Reservation.new(
        product: @instrument,
        reserve_start_at: @now,
        reserve_end_at: @now + @ipp.usage_mins.minutes,
      )
    end

    context "free with actuals" do
      before :each do
        @ipp.update_attributes(usage_rate: 0, usage_subsidy: 0)
        yesterday = @now - 1.day
        end_time = yesterday + 1.hour
        @reservation.update_attributes(
          reserve_start_at: yesterday,
          reserve_end_at: end_time,
          actual_start_at: yesterday,
          actual_end_at: end_time,
        )
      end

      it "should return zero for zero priced policy" do
        @costs = @ipp.calculate_cost_and_subsidy(@reservation)
        expect(@costs).to eq(cost: 0, subsidy: 0)
      end

      it "should return minimum cost for a zero priced policy" do
        @ipp.update_attribute :minimum_cost, 20
        @costs = @ipp.calculate_cost_and_subsidy(@reservation)
        expect(@costs).to eq(cost: 20, subsidy: 0)
      end
    end

    it "should return nil if an instrument is free and the reservation requires but is missing actuals" do
      @ipp.update_attributes(usage_rate: 0, usage_subsidy: 0)
      expect(@reservation).to be_requires_but_missing_actuals
      expect(@ipp.calculate_cost_and_subsidy(@reservation)).to be_nil
    end

    it "should correctly calculate cost with usage rate and subsidy" do
      @reservation.actual_start_at = @reservation.reserve_start_at
      @reservation.actual_end_at = @reservation.reserve_end_at
      @costs = @ipp.calculate_cost_and_subsidy(@reservation)
      expect(@costs).to eq(cost: 100, subsidy: 99)
    end

    it "should correctly calculate cost with usage rate and subsidy and overage using usage rate for overage rate and usage subsidy for overage subsidy" do
      # actual usage == twice as long as the reservation window
      @reservation.actual_start_at = @reservation.reserve_start_at
      @reservation.actual_end_at = @reservation.actual_start_at + (@ipp.usage_mins * 2).minutes

      @costs = @ipp.calculate_cost_and_subsidy(@reservation)

      expect(@costs[:subsidy]).to eq(@ipp.usage_subsidy * 2)
    end

    it "should have at least one block even if the actual times are within a minute of each other" do
      @reservation.actual_start_at = @reservation.reserve_start_at
      @reservation.actual_end_at = @reservation.actual_start_at + 10.seconds

      @costs = @ipp.calculate_cost_and_subsidy(@reservation)
      expect(@costs[:cost]).to eq(100)
      expect(@costs[:subsidy]).to eq(99)
    end

    context "overage" do
      before :each do
        @ipp.update_attributes(overage_rate: 200, overage_subsidy: 199)
      end
      it "should not overage for less than one minute" do
        @reservation.actual_start_at = @reservation.reserve_start_at
        @reservation.actual_end_at = @reservation.reserve_end_at + 10.seconds
        @costs = @ipp.calculate_cost_and_subsidy(@reservation)
        expect(@costs[:cost]).to eq(100)
        expect(@costs[:subsidy]).to eq(99)
      end

      it "should charge a full interval for more than one minute over" do
        @reservation.actual_start_at = @reservation.reserve_start_at
        @reservation.actual_end_at = @reservation.reserve_end_at + 61.seconds
        @costs = @ipp.calculate_cost_and_subsidy(@reservation)
        expect(@costs[:cost]).to eq(300)
        expect(@costs[:subsidy]).to eq(298)
      end
    end

    context "reservation only instrument" do
      before :each do
        allow(@instrument).to receive(:control_mechanism).and_return Relay::CONTROL_MECHANISMS[:manual]
      end

      context "with reservation rates" do
        before :each do
          @ipp.update_attributes!(reservation_rate: 100, reservation_subsidy: 99, usage_rate: nil, usage_subsidy: nil)
        end

        context "without actual time" do
          it "should calculate cost" do
            @costs = @ipp.calculate_cost_and_subsidy(@reservation)
            expect(@costs[:cost]).to eq(100)
            expect(@costs[:subsidy]).to eq(99)
          end
        end

        context "with actual time" do
          before :each do
            @reservation.actual_start_at = @reservation.reserve_start_at
            @reservation.actual_end_at = @reservation.reserve_end_at
          end

          it "should calculate the cost and subsidy" do
            @costs = @ipp.calculate_cost_and_subsidy(@reservation)
            expect(@costs[:cost]).to eq(100)
            expect(@costs[:subsidy]).to eq(99)
          end
        end
      end

      context "with usage rates instead of reservation rates" do
        before :each do
          @ipp.update_attributes!(reservation_rate: nil, reservation_subsidy: nil,
                                  usage_rate: 100, usage_subsidy: 99)
        end
        it "should return nil" do
          @costs = @ipp.calculate_cost_and_subsidy(@reservation)
          expect(@costs).to be_nil
        end
      end
    end

    it "should return nil for calculate cost with reservation and overage rate without actual hours" do
      @reservation.actual_start_at = nil
      @reservation.actual_end_at = nil
      @ipp.update_attributes(overage_rate: 120, overage_subsidy: 119)
      expect(@ipp.calculate_cost_and_subsidy(@reservation)).to be_nil
    end

  end
end
