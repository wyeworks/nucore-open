# frozen_string_literal: true

require "rails_helper"
require "product_shared_examples"

RSpec.describe Instrument do
  it_should_behave_like "ReservationProduct", :instrument

  let(:facility) { FactoryBot.create(:setup_facility) }
  subject(:instrument) { build :instrument, facility: facility }

  it "should create using factory" do
    expect(instrument).to be_valid
    expect(instrument.type).to eq("Instrument")
  end

  [:min_reserve_mins, :auto_cancel_mins].each do |attr|
    it "should require #{attr} to be >= 0 and integers only" do
      instrument.min_reserve_mins = 0
      is_expected.to allow_value(0).for(attr)
      is_expected.to allow_value(nil).for(attr)
      is_expected.not_to allow_value(-1).for(attr)
      is_expected.not_to allow_value(5.1).for(attr)
    end
  end

  describe "min/max reservation is a multiple of reservation interval" do
    subject { instrument }
    let(:reserve_interval) { 5 }
    let(:min_reserve_mins) { 1 }
    let(:max_reserve_mins) { 1000 }

    before do
      instrument.assign_attributes(reserve_interval: reserve_interval,
                                   min_reserve_mins: min_reserve_mins,
                                   max_reserve_mins: max_reserve_mins)
    end

    describe "min reservation" do
      context "is a multiple" do
        let(:min_reserve_mins) { reserve_interval * 4 }
        it "does not have an error" do
          instrument.valid?
          expect(instrument.errors[:min_reserve_mins]).to be_blank
        end
      end

      context "is not a multiple" do
        let(:min_reserve_mins) { reserve_interval * 4 + 1 }

        it "is is not valid" do
          expect(instrument).not_to be_valid
          expect(instrument.errors[:min_reserve_mins]).to be_present
        end
      end

      context "when the reservation interval is not set" do
        let(:reserve_interval) { nil }
        it "does not error" do
          expect { instrument.valid? }.not_to raise_error
          expect(instrument.errors[:reserve_interval]).to be_present
        end
      end
    end

    describe "max reservation" do
      context "is a multiple" do
        let(:max_reserve_mins) { reserve_interval * 4 }
        it "does not have an error" do
          instrument.valid?
          expect(instrument.errors[:max_reserve_mins]).to be_blank
        end
      end

      context "is not a multiple" do
        let(:max_reserve_mins) { reserve_interval * 4 + 1 }

        it "is not valid" do
          expect(instrument).not_to be_valid
          expect(instrument.errors[:max_reserve_mins]).to be_present
        end
      end

      context "when the maximum reservation is less than the minimum reservation" do
        let(:min_reserve_mins) { 10 }
        let(:max_reserve_mins) { 5 }

        it "is not valid" do
          expect(instrument).not_to be_valid
          expect(instrument.errors[:max_reserve_mins]).to be_present
        end
      end

      context "when the reservation interval is not set" do
        let(:reserve_interval) { nil }
        it "does not error" do
          expect { instrument.valid? }.not_to raise_error
          expect(instrument.errors[:reserve_interval]).to be_present
        end
      end
    end
  end

  it { is_expected.to validate_inclusion_of(:reserve_interval).in_array Instrument::RESERVE_INTERVALS }

  describe "shared schedules" do
    subject(:instrument) do
      FactoryBot.build(:instrument,
                       facility: facility,
                       schedule: schedule)
    end

    context "when no schedule is defined" do
      let(:schedule) { nil }

      it "creates a default schedule", :aggregate_failures do
        expect { instrument.save! }.to change(instrument, :schedule).from(nil)
      end
    end

    context "when a schedule is defined" do
      let(:schedule) { FactoryBot.create(:schedule, facility: facility) }

      it "does not create a new schedule" do
        expect { instrument.save! }
          .not_to change(instrument, :schedule).from(schedule)
      end
    end

    describe "name updating" do
      before :each do
        @instrument = setup_instrument(schedule: nil)
        @instrument2 = FactoryBot.create(:setup_instrument, schedule: @instrument.schedule)
        assert @instrument.schedule == @instrument2.schedule
      end

      it "should update the schedule's name when updating the primary instrument's name" do
        @instrument.update_attributes(name: "New Name")
        expect(@instrument.schedule.reload.name).to eq("New Name Schedule")
      end

      it "should not call update_schedule_name if name did not change" do
        expect(@instrument).to receive(:update_schedule_name).never
        @instrument.update_attributes(description: "a description")
      end

      it "should not update the schedule's name when updating the secondary instrument" do
        @instrument2.update_attributes(name: "New Name")
        expect(@instrument2.schedule.reload.name).to eq("#{@instrument.name} Schedule")
      end
    end
  end

  context "updating nested relay" do
    before :each do
      @instrument = FactoryBot.create(:instrument,
                                      facility: facility,
                                      no_relay: true)
    end

    context "existing type: 'timer' (Timer without relay)" do
      before :each do
        @instrument.relay = RelayDummy.new(instrument: @instrument)
        @instrument.relay.save!
        expect(@instrument.control_mechanism).to eq("timer")
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(control_mechanism: "relay", relay_attributes: { type: "RelaySynaccessRevA" })
          end

          it "should fail" do
            expect(@updated).to be false
          end

          it "should have errors" do
            expect(@instrument.errors.full_messages).not_to eq([])
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(control_mechanism: "relay", relay_attributes: FactoryBot.attributes_for(:relay))
          end

          it "should succeed" do
            expect(@updated).to be true
          end

          it "should have no errors" do
            expect(@instrument.errors.full_messages).to eq([])
          end

          it "should have control mechanism of relay" do
            expect(@instrument.reload.control_mechanism).to eq("relay")
          end
        end
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(control_mechanism: "manual")
        end

        it "should succeed" do
          expect(@updated).to be true
        end

        it "should have a control_mechanism of manual" do
          expect(@instrument.reload.control_mechanism).to eq("manual")
        end

        it "should destroy the relay" do
          expect(@instrument.reload.relay).to be_nil
        end
      end
    end

    context "existing type: RelaySynaccessA" do
      before :each do
        FactoryBot.create(:relay, instrument_id: @instrument.id)
        expect(@instrument.reload.control_mechanism).to eq("relay")
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(control_mechanism: "manual")
        end

        it "should succeed" do
          expect(@updated).to be true
        end

        it "should have a control_mechanism of manual" do
          expect(@instrument.reload.control_mechanism).to eq("manual")
        end

        it "should destroy the relay" do
          expect(@instrument.reload.relay).to be_nil
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(control_mechanism: "timer")
        end

        it "should succeed" do
          expect(@updated).to be true
        end

        it "control mechanism should be a timer" do
          expect(@instrument.reload.control_mechanism).to eq("timer")
        end
      end

      context "just running a validation" do
        it "does not affect the relay" do
          expect(@instrument).to be_valid
          expect(@instrument.reload.relay).to be_present
        end
      end
    end

    context "existing type: manual 'Reservation Only'" do
      before :each do
        @instrument.relay.destroy if @instrument.relay
        expect(@instrument.reload.control_mechanism).to eq(Relay::CONTROL_MECHANISMS[:manual])
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(control_mechanism: "relay", relay_attributes: { type: "RelaySynaccessRevA" })
          end

          it "should fail" do
            expect(@updated).to be false
          end

          it "should have errors" do
            expect(@instrument.errors.full_messages).not_to eq([])
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(control_mechanism: "relay", relay_attributes: FactoryBot.attributes_for(:relay))
          end
          it "should succeed" do
            expect(@updated).to be true
          end

          it "should have no errors" do
            expect(@instrument.errors.full_messages).to eq([])
          end

          it "should have control mechanism of relay" do
            expect(@instrument.reload.control_mechanism).to eq("relay")
          end
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(control_mechanism: "timer")
        end

        it "should succeed" do
          expect(@updated).to be true
        end

        it "control mechanism should be a timer" do
          expect(@instrument.reload.control_mechanism).to eq("timer")
        end
      end
    end
  end

  context "reservations with schedule rules from 9 am to 5 pm every day, with 60 minute durations" do
    before(:each) do
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument = FactoryBot.create(:instrument,
                                      facility: facility,
                                      min_reserve_mins: 60,
                                      max_reserve_mins: 60)
      assert @instrument.valid?
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
      assert @rule.valid?
      allow_any_instance_of(Reservation).to receive(:admin?).and_return(false)
    end

    it "should not allow reservation in the past" do
      @reservation = @instrument.reservations.create(reserve_start_at: Time.zone.now - 1.hour, reserve_end_at: Time.zone.now)
      assert @reservation.errors[:reserve_start_at]
    end

    it "should not allow 1 hour reservation for a time not between 9 and 5" do
      # 8 am - 9 am
      @start       = Time.zone.tomorrow.beginning_of_day + 8.hours
      @reservation = @instrument.reservations.create(reserve_start_at: @start, reserve_end_at: @start + 1.hour)
      assert @reservation.errors[:base]
    end

    it "should not allow a 2 hour reservation" do
      # 8 am - 10 pam
      @start       = Time.zone.tomorrow.beginning_of_day + 9.hours
      @reservation = @instrument.reservations.create(reserve_start_at: @start, reserve_end_at: @start + 2.hours)
      assert @reservation.errors[:base]
    end

    it "should allow 1 hour reservations between 9 and 5" do
      # 9 am - 10 am
      @start        = Time.zone.tomorrow.beginning_of_day + 9.hours
      @reservation1 = @instrument.reservations.create(reserve_start_at: @start, reserve_end_at: @start + 1.hour)
      assert @reservation1.valid?
      # should allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start + 1.hour, reserve_end_at: @start + 2.hours)
      assert @reservation2.valid?
      # should find 2 upcoming reservations when both are in the future
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming
      # should find 2 upcoming reservations when both are in the future or happening now
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming(@start + 1.minute)
      # should find 1 upcoming when 1 is in the past
      assert_equal [@reservation2], @instrument.reservations.upcoming(@reservation1.reserve_end_at + 1.minute)
    end

    it "should allow 1 hour reservations between 9 and 5, using duration_mins" do
      # 9 am - 10 am
      @start        = Time.zone.tomorrow.beginning_of_day + 9.hours
      @reservation1 = @instrument.reservations.create(reserve_start_at: @start,
                                                      duration_mins: 60,
                                                      split_times: true)
      assert @reservation1.valid?
      assert_equal 60, @reservation1.reload.duration_mins
    end

    it "should not allow overlapping reservations between 9 and 5" do
      # 10 am - 11 am
      @start        = Time.zone.tomorrow.beginning_of_day + 10.hours
      @reservation1 = @instrument.reservations.create(reserve_start_at: @start,
                                                      reserve_end_at: @start + 1.hour,
                                                      split_times: true)
      assert @reservation1.valid?
      # not allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start,
                                                      reserve_end_at: @start + 1.hour,
                                                      split_times: true)
      expect(@reservation2.errors[:base]).not_to be_empty
      # not allow 9:30 am - 10:30 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start - 30.minutes,
                                                      reserve_end_at: @start + 30.minutes,
                                                      split_times: true)
      expect(@reservation2.errors[:base]).not_to be_empty
      # not allow 9:30 am - 10:30 am, using reserve_start_date, reserve_start_hour, reserve_start_min, reserve_start_meridian
      @reservation2 = @instrument.reservations.create(reserve_start_date: @start.to_s,
                                                      reserve_start_hour: "9",
                                                      reserve_start_min: "30",
                                                      reserve_start_meridian: "am",
                                                      duration_mins: "60",
                                                      split_times: true)
      expect(@reservation2.errors[:base]).not_to be_empty
      # not allow 9:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start - 30.minutes, reserve_end_at: @start + 90.minutes)
      expect(@reservation2.errors[:base]).not_to be_empty
      # not allow 10:30 am - 10:45 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start + 30.minutes, reserve_end_at: @start + 45.minutes)
      expect(@reservation2.errors[:base]).not_to be_empty
      # not allow 10:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start + 30.minutes, reserve_end_at: @start + 90.minutes)
      expect(@reservation2.errors[:base]).not_to be_empty
    end

    it "should allow adjacent reservations" do
      # 10 am - 11 am
      @start        = Time.zone.tomorrow.beginning_of_day + 10.hours
      @reservation1 = @instrument.reservations.create(reserve_start_at: @start, reserve_end_at: @start + 1.hour)
      assert @reservation1.valid?
      # should allow 9 am - 10 am
      @reservation2 = @instrument.reservations.create(reserve_start_at: @start - 1.hour, reserve_end_at: @start)
      assert @reservation2.valid?
      # should allow 11 am - 12 pm
      @reservation3 = @instrument.reservations.create(reserve_start_at: @start + 1.hour, reserve_end_at: @start + 2.hours)
      assert @reservation3.valid?
    end
  end

  context "next available reservation based on schedule rules" do
    before(:each) do
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument = create(:instrument,
                           facility: facility,
                           min_reserve_mins: 60,
                           reserve_interval: 60,
                           max_reserve_mins: 60)
      assert @instrument.valid?
      # add rule, available every day from 9 to 5, 60 minutes duration/interval
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
      assert @rule.valid?
      # stub so today at 9 am is not in the future
      allow_any_instance_of(Reservation).to receive(:in_the_future).and_return(true)
    end

    it "should find next available reservation with 60 minute interval rule, without any pending reservations" do
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      # find next reservation after 9:01 am today at 10 am today
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day + 9.hours + 1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 4:01 pm today at 9 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day + 16.hours + 1.minute)
      assert_equal (Time.zone.now + 1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
    end

    it "should find the next available reservation even if it is far in the future" do
      res_start = Time.zone.now.beginning_of_day
      res_end = res_start + 10.days
      reservation = @instrument.reservations.create reserve_start_at: res_start, reserve_end_at: res_end
      expect(reservation).to be_valid
      next_reservation = @instrument.next_available_reservation(after: res_start)
      expect(next_reservation.reserve_start_at).to be > res_end
      expect(next_reservation.reserve_start_at).to eq @instrument.next_available_reservation(after: res_end).reserve_start_at
    end

    it "should find next available reservation with 5 minute interval rule, without any pending reservations" do
      expect(@rule.product.update_attribute :reserve_interval, 5).to be true
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 9:01 am today at 9:05 am today
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day + 9.hours + 1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 5, @next_reservation.reserve_start_at.min
      # find next reservation after 3:45 pm today at 3:45 pm today
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day + 15.hours + 45.minutes)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 15, @next_reservation.reserve_start_at.hour
      assert_equal 45, @next_reservation.reserve_start_at.min
    end

    context "with cutoff hours" do
      let(:next_reservation) { @instrument.next_available_reservation(after: Time.zone.now.beginning_of_day) }

      before { @rule.product.update_attribute :cutoff_hours, 10 }

      it "finds the next available reservation with cutoff hours" do
        assert_equal (Time.zone.now + 1.day).day, next_reservation.reserve_start_at.day
        assert_equal 9, next_reservation.reserve_start_at.hour
        assert_equal 0, next_reservation.reserve_start_at.min
      end
    end

    it "should find next available reservation with pending reservations" do
      @start        = Time.zone.tomorrow.beginning_of_day.advance(hours: 9)
      @reservation1 = @instrument.reservations.create(reserve_start_at: @start,
                                                      duration_mins: 60,
                                                      split_times: true)
      assert @reservation1.valid?
      # find next reservation after 12 am tomorrow at 10 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after: Time.zone.tomorrow.beginning_of_day)
      assert_equal (Time.zone.now + 1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
    end
  end

  context "available hours based on schedule rules" do
    before(:each) do
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument = FactoryBot.create(:instrument,
                                      facility: facility,
                                      min_reserve_mins: 60,
                                      max_reserve_mins: 60)
      assert @instrument.valid?
    end

    it "should default to 0 and 23 if no schedule rules" do
      expect(@instrument.first_available_hour).to eq(0)
      expect(@instrument.last_available_hour).to eq(23)
    end

    context "with a mon-friday rule from 9-5" do
      before :each do
        # add rule, monday-friday from 9 to 5, 60 minutes duration
        @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule, on_sun: false, on_sat: false))
        assert @rule.valid?
      end

      it "should have first avail hour at 9 am, last avail hour at 4 pm" do
        expect(@instrument.first_available_hour).to eq(9)
        expect(@instrument.last_available_hour).to eq(16)
      end

      context "with a weekend reservation going from 8-6" do
        before :each do
          @rule2 = @instrument.schedule_rules.create(FactoryBot.attributes_for(:weekend_schedule_rule,
                                                                               start_hour: 8,
                                                                               end_hour: 18))
          assert @rule2.valid?
        end

        it "should have first avail hour at 8 am, last avail hour at 6 pm" do
          expect(@instrument.first_available_hour).to eq(8)
          expect(@instrument.last_available_hour).to eq(17)
        end
      end
    end
  end

  context "last reserve dates, days from now" do
    before(:each) do
      @price_group = FactoryBot.create(:price_group, facility: facility)
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument = FactoryBot.create(:instrument,
                                      facility: facility,
                                      min_reserve_mins: 60,
                                      max_reserve_mins: 60)
      @price_group_product = FactoryBot.create(:price_group_product, product: @instrument, price_group: @price_group)
      assert @instrument.valid?

      # create price policy with default window of 1 day
      @price_policy = @instrument.instrument_price_policies.create(FactoryBot.attributes_for(:instrument_price_policy).update(price_group_id: @price_group.id))
    end

    it "should have last_reserve_date == tomorrow, last_reserve_days_from_now == 1 when window is 1" do
      @instrument.price_group_products.each { |pgp| pgp.update_attributes(reservation_window: 1) }
      assert_equal Time.zone.now.to_date + 1.day, @instrument.reload.last_reserve_date
      assert_equal 1, @instrument.max_reservation_window
    end

    it "should use max window of all price polices to calculate dates" do
      # create price policy with window of 15 days
      @price_group_product.reservation_window = 15
      assert @price_group_product.save
      @options       = FactoryBot.attributes_for(:instrument_price_policy).update(price_group_id: @price_group.id)
      @price_policy2 = @instrument.instrument_price_policies.new(@options)
      @price_policy2.save(validate: false) # save without validations
      assert_equal 15, @instrument.max_reservation_window
      assert_equal (Time.zone.now + 15.days).to_date, @instrument.last_reserve_date
    end
  end

  context "can_purchase?" do
    let(:account) { create(:setup_account) }
    let(:price_policy_ids) { account.price_groups.map(&:id) }

    before :each do
      @instrument = FactoryBot.create(:instrument,
                                      facility: facility)
      @price_group = FactoryBot.create(:price_group, facility: facility)
      @user = FactoryBot.create(:user)
      @price_group_member = create(:account_price_group_member, account: account, price_group: @price_group)
      @user.reload
      @price_policy = FactoryBot.create(:instrument_price_policy, product: @instrument, price_group: @price_group)
      # TODO: remove this line
      FactoryBot.create(:price_group_product, price_group: @price_group, product: @instrument)
    end

    it "should be purchasable if there are schedule rules" do
      @schedule_rule = FactoryBot.create(:schedule_rule, product: @instrument)
      expect(@instrument.reload).to be_can_purchase(price_policy_ids)
    end

    it "should not be purchasable if there are no schedule rules" do
      expect(@instrument).not_to be_can_purchase(price_policy_ids)
    end

    context "with schedule rules" do
      before :each do
        @schedule_rule = FactoryBot.create(:schedule_rule, product: @instrument)
        @instrument.reload
      end
      it "should be purchasable if there are schedule rules" do
        expect(@instrument).to be_can_purchase(price_policy_ids)
      end

      context "with no price policies at all" do
        before :each do
          @instrument.price_policies.clear
        end
        it "should have no price policies" do
          expect(@instrument.price_policies).to be_empty
        end
        it "should not be purchasable" do
          expect(@instrument).not_to be_can_purchase(price_policy_ids)
        end
      end

      context "with current price polices, but not for user" do
        it "should be set up right" do
          expect(@instrument.price_policies.current).not_to be_empty
          expect(@user.price_groups).not_to include @price_group
        end

        it "should not be purchasable" do
          expect(@instrument).not_to be_can_purchase(@user.price_groups.map(&:id))
        end
      end

      context "with expired price policies for user" do
        before :each do
          @price_policy.update_attributes(start_date: 10.days.ago, expire_date: 1.day.ago)
        end

        it "should be set up right" do
          expect(@instrument.price_policies.current).to be_empty
        end

        it "should be purchasable" do
          expect(@instrument).to be_can_purchase(price_policy_ids)
        end
      end

      context "with expired price policies, but not for user" do
        before :each do
          @price_policy.update_attributes(start_date: 10.days.ago, expire_date: 1.day.ago)
        end

        it "should be set up right" do
          expect(@instrument.price_policies.current).to be_empty
          expect(@instrument.price_policies).not_to be_empty
          expect(@user.price_groups).not_to include @price_groups
        end

        it "should not be purchasable" do
          expect(@instrument).not_to be_can_purchase(@user.price_groups.map(&:id))
        end

      end
    end

  end

  describe "walkup_available?" do
    subject(:instrument) { FactoryBot.create :setup_instrument }

    it { is_expected.to be_walkup_available }

    context "there is not a current schedule rule" do
      before :each do
        instrument.schedule_rules.destroy_all
      end

      it { is_expected.not_to be_walkup_available }
    end

    context "zero minimum reservation" do
      before :each do
        instrument.update_attributes(min_reserve_mins: 0)
      end
      it { is_expected.to be_walkup_available }
    end

    context "with nil minimum reservation" do
      before :each do
        instrument.update_attributes(min_reserve_mins: nil)
      end
      it { is_expected.to be_walkup_available }
    end

    context "with an admin reservation" do
      let!(:reservation) do
        FactoryBot.create(:admin_reservation,
                          reserve_start_at: 30.minutes.ago,
                          reserve_end_at: 30.minutes.from_now,
                          product: instrument)
      end

      it { is_expected.not_to be_walkup_available }
    end

    context "reservation only instrument" do
      context "with a current reservation" do
        let!(:reservation) do
          FactoryBot.create :purchased_reservation,
                            reserve_start_at: 30.minutes.ago,
                            reserve_end_at: 30.minutes.from_now,
                            product: instrument
        end

        it { is_expected.not_to be_walkup_available }

        context "but it was canceled" do
          let(:user) { FactoryBot.build :user }
          before :each do
            travel_to_and_return(60.minutes.ago) do
              reservation.order_detail.update_order_status! user, OrderStatus.canceled
              expect(reservation).to be_canceled
            end
          end

          it { is_expected.to be_walkup_available }
        end
      end

      context "with no minimum reservation" do
        before :each do
          instrument.update_attributes!(min_reserve_mins: nil)
        end

        it { is_expected.to be_walkup_available }
      end
    end

    context "instrument with timer" do
      before :each do
        instrument.update_attributes!(control_mechanism: "manual")
      end

      context "with a current reservation" do
        let!(:reservation) do
          FactoryBot.create :purchased_reservation,
                            reserve_start_at: 30.minutes.ago,
                            reserve_end_at: 30.minutes.from_now,
                            product: instrument
        end

        context "and is started" do
          before :each do
            reservation.update_attributes(reserved_by_admin: true,
                                          actual_start_at: 30.minutes.ago)
          end

          it { is_expected.not_to be_walkup_available }

          context "but it was ended already" do
            before :each do
              reservation.update_attributes(reserved_by_admin: true,
                                            actual_end_at: 10.minutes.ago)
            end

            it { is_expected.to be_walkup_available }
          end
        end
      end
    end
  end

  describe "#online!" do
    before { instrument.save! }

    context "when the instrument is offline" do
      let!(:offline_reservation) do
        instrument
          .offline_reservations
          .create!(
            admin_note: "Down",
            category: "out_of_order",
            reserve_start_at: 1.day.ago,
          )
      end

      it "switches the instrument to be online" do
        expect { instrument.online! }
          .to change { instrument.reload.online? }
          .from(false).to(true)
          .and change { offline_reservation.reload.reserve_end_at }.from(nil)
      end
    end

    context "when the instrument is online" do
      it "remains online" do
        expect { instrument.online! }
          .not_to change(instrument, :online?).from(true)
      end
    end
  end

  describe "#offline? and #online?" do
    before { instrument.save! }

    context "when an offline reservation does not exist" do
      it "is online", :aggregate_failures do
        is_expected.to be_online
        is_expected.not_to be_offline
      end
    end

    context "when an offline reservation exists", :aggregate_failures do
      let!(:offline_reservation) do
        instrument
          .offline_reservations
          .create!(
            admin_note: "Down",
            category: "out_of_order",
            reserve_start_at: 1.day.ago,
          )
      end

      it "is offline", :aggregate_failures do
        is_expected.to be_offline
        is_expected.not_to be_online
      end
    end
  end

  describe "#offline_category" do
    context "when online" do
      it { expect(subject.offline_category).to be_blank }
    end

    context "when offline" do
      subject(:instrument) { FactoryBot.create(:setup_instrument, :offline) }

      it { expect(subject.offline_category).to eq("out_of_order") }
    end
  end

  describe "issue_report_recipients" do
    before do
      instrument.issue_report_recipients = "test1@example.com, test2@example.com"
    end

    it "treats it as a string" do
      expect(instrument.issue_report_recipients).to eq("test1@example.com, test2@example.com")
    end

    it "can interpret it as an array" do
      expect(instrument.issue_report_recipients.to_a).to eq(["test1@example.com", "test2@example.com"])
    end
  end

  describe "#blackout_reservations" do
    context "for an instrument available only from 9 AM to 5 PM" do
      let(:now) { Time.zone.parse("2015-07-05T12:14:00") }
      let(:reservations) { instrument.blackout_reservations(now) }

      before(:each) do
        instrument.save!
        instrument.schedule_rules.create!(FactoryBot.attributes_for(:schedule_rule))
      end

      it "returns two dummy reservations" do
        expect(reservations.size).to eq(2)

        reservations.each do |reservation|
          expect(reservation).to be_kind_of(Reservation)
          expect(reservation).to be_blackout
          expect(reservation).not_to be_persisted
        end
      end

      it "reserves midnight to 9 AM as unavailable" do
        expect(reservations.first.reserve_start_at).to eq(now.beginning_of_day)
        expect(reservations.first.reserve_end_at).to eq(Time.zone.parse("2015-07-05T09:00:00"))
      end

      it "reserves 5 PM to midnight as unavailable" do
        expect(reservations.last.reserve_start_at).to eq(Time.zone.parse("2015-07-05T17:00:00"))
        expect(reservations.last.reserve_end_at).to eq(Time.zone.parse("2015-07-06T00:00:00"))
      end
    end
  end
end
