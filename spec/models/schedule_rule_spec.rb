# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduleRule do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility: facility) }

  it "should create using factory" do
    instrument = FactoryBot.create(:instrument,
                                   facility: facility)
    rule = FactoryBot.create(:schedule_rule, product: instrument)
    expect(rule).to be_valid
  end

  context "times" do
    it "should not be valid with start hours outside 0-24" do
      is_expected.not_to allow_value(-1).for(:start_hour)
      is_expected.not_to allow_value(25).for(:start_hour)
      is_expected.to allow_value(0).for(:start_hour)
      is_expected.to allow_value(23).for(:start_hour)
    end

    it "should not be valid with start mins outside 0-59" do
      is_expected.not_to allow_value(-1).for(:end_min)
      is_expected.not_to allow_value(60).for(:end_min)
      is_expected.to allow_value(0).for(:end_min)
      is_expected.to allow_value(59).for(:end_min)
    end

    it "should allow all day rule" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      @options = { start_hour: 0, start_min: 0, end_hour: 24, end_min: 0 }
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule).merge(@options))
      assert @rule.valid?
    end

    it "should not allow end_hour == 24 and end_min != 0" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      @options = { start_hour: 0, start_min: 0, end_hour: 24, end_min: 1 }
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule).merge(@options))
      assert @rule.invalid?
      assert_equal ["End time is invalid"], @rule.errors[:base]
    end

    it "should recognize inclusive datetimes" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      @rule = @instrument.schedule_rules.build(FactoryBot.attributes_for(:schedule_rule))
      expect(@rule).to be_cover(Time.zone.local(1981, 9, 15, 12, 0, 0))
    end

    it "should not recognize non-inclusive datetimes" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      @rule = @instrument.schedule_rules.build(FactoryBot.attributes_for(:schedule_rule))
      expect(@rule).not_to be_cover(Time.zone.local(1981, 9, 15, 3, 0, 0))
    end
  end

  it "should not allow rule conflicts" do
    @facility = FactoryBot.create(:setup_facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @facility)
    @instrument = FactoryBot.create(:instrument,
                                    facility: @facility,
                                    facility_account: @facility_account)
    # create rule every day from 9 am to 5 pm
    @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
    assert @rule.valid?

    # not allow rule from 9 am to 5 pm
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 9, end_hour: 17)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 9 am to 10 am
    @options = FactoryBot.attributes_for(:schedule_rule).merge(end_hour: 10)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 10 am to 11 am
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 10, end_hour: 11)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 3 pm to 5 pm
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 15, end_hour: 17)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 7 am to 10 am
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 7, end_hour: 10)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 4 pm to 10 pm
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 16, end_hour: 22)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 8 am to 8 pm
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 8, end_hour: 20)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]
  end

  it "should allow adjacent rules" do
    @facility = FactoryBot.create(:setup_facility)
    @instrument = FactoryBot.create(:instrument,
                                    facility: @facility)
    # create rule every day from 9 am to 5 pm
    @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
    assert @rule.valid?

    # allow rule from 7 am to 9 am
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 7, end_hour: 9)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?

    # allow rule from 5 pm to 12am
    @options = FactoryBot.attributes_for(:schedule_rule).merge(start_hour: 17, end_hour: 24)
    @rule1 = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?
  end

  # it "should not conflict with existing reservation" do
  #   @facility = FactoryBot.create(:setup_facility)
  #   @facility_account = FactoryBot.create(:facility_account, facility: @facility)
  #   @instrument = @facility.instruments.create(FactoryBot.attributes_for(:instrument, :facility_account_id => @facility_account.id))
  #   # create rule every day from 9 am to 5 pm
  #   @rule1 = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
  #   assert @rule1.valid?
  #
  #   # start/end at the exact same time
  #   @rule2 = @instrument.schedule_rules.build(FactoryBot.attributes_for(:schedule_rule))
  #   @rule2.should_not be_valid
  #
  #   # start/end one hour before valid rule, but times overlap
  #   @rule2.start_hour = @rule2.start_hour - 1
  #   @rule2.end_hour = @rule2.end_hour - 1
  #   @rule2.should_not be_valid
  # end

  it "should not be valid with an end time after the start time" do
    @facility = FactoryBot.create(:setup_facility)
    @instrument = FactoryBot.create(:instrument,
                                    facility: @facility)
    # create rule every day from 9 am to 5 pm
    @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
    assert @rule.valid?

    @rule.start_hour = 9
    @rule.start_min = 00
    @rule.end_hour = 9
    @rule.end_min = 00
    expect(@rule).not_to be_valid

    @rule.end_hour = 8
    @rule.end_min = 20
    expect(@rule).not_to be_valid
  end

  context "calendar object" do
    it "should build calendar object for 9-5 rule every day" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      # create rule every day from 9 am to 5 pm
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule, discount_percent: 5))
      assert @rule.valid?

      # find past sunday, and build calendar object
      @sunday = Time.current.beginning_of_week(:sunday).to_date
      @calendar = @rule.as_calendar_objects

      # each title should be the same
      @calendar.each do |hash|
        expect(hash["title"]).to eq("Discount: 5%")
        expect(hash["allDay"]).to eq(false)
      end

      # days should start with this past sunday and end next saturday
      @calendar.each_with_index do |hash, i|
        expect(Time.zone.parse(hash["start"])).to eq(Time.zone.parse("#{@sunday + i.days} 9:00"))
        expect(Time.zone.parse(hash["end"])).to eq(Time.zone.parse("#{@sunday + i.days} 17:00"))
      end

      # build unavailable rules from the available rules collection
      @not_available = ScheduleRule.unavailable(@rule)
      expect(@not_available.size).to eq(14)
      # should mark each rule as unavailable
      assert_equal true, @not_available.first.unavailable
      @not_calendar = @not_available.collect(&:as_calendar_objects).flatten

      # days should be same as above
      # even times should be 12 am to 9 am
      # odd times should be 5 pm to 12 pm
      even = (0..@not_available.size).select(&:even?)
      odd = (0..@not_available.size).select(&:odd?)

      even.collect { |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        expect(Time.zone.parse(hash["start"])).to eq(Time.zone.parse((@sunday + i.days).to_s))
        expect(Time.zone.parse(hash["end"])).to eq(Time.zone.parse("#{@sunday + i.days} 9:00"))
      end

      odd.collect { |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        expect(Time.zone.parse(hash["start"])).to eq(Time.zone.parse("#{@sunday + i.days} 17:00"))
        expect(Time.zone.parse(hash["end"])).to eq(Time.zone.parse((@sunday + (i + 1).days).to_s))
      end

      # should set calendar objects title to ''
      @not_calendar.each do |hash|
        expect(hash["title"]).to eq("")
      end
    end

    it "should build calendar object using multiple rules on the same day" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility,
                                      reserve_interval: 60)
      # create rule tue 1 am - 3 am
      @options = {
        on_mon: false, on_tue: true, on_wed: false, on_thu: false, on_fri: false, on_sat: false, on_sun: false,
        start_hour: 1, start_min: 0, end_hour: 3, end_min: 0, discount_percent: 0
      }

      @rule1 = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?

      # create rule tue 7 am - 9 am
      @options = {
        on_mon: false, on_tue: true, on_wed: false, on_thu: false, on_fri: false, on_sat: false, on_sun: false,
        start_hour: 7, start_min: 0, end_hour: 9, end_min: 0, discount_percent: 0
      }

      @rule2 = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday = Time.current.beginning_of_week(:sunday).to_date + 2

      # times should be tue 1 am - 3 am
      @calendar1 = @rule1.as_calendar_objects
      @calendar1.each_with_index do |hash, _i|
        expect(Time.zone.parse(hash["start"])).to eq(@tuesday + 1.hour)
        expect(Time.zone.parse(hash["end"])).to eq(@tuesday + 3.hours)
      end

      # times should be tue 7 am - 9 am
      @calendar2 = @rule2.as_calendar_objects
      @calendar2.each_with_index do |hash, _i|
        expect(Time.zone.parse(hash["start"])).to eq(@tuesday + 7.hours)
        expect(Time.zone.parse(hash["end"])).to eq(@tuesday + 9.hours)
      end

      # build not available rules from the available rules collection, 3 for tue and 1 each for rest of days
      @not_available = ScheduleRule.unavailable([@rule1, @rule2])
      expect(@not_available.size).to eq(9)
      @not_calendar = @not_available.collect(&:as_calendar_objects).flatten

      # rules for tuesday should be 12am-1am, 3am-7am, 9pm-12pm
      @tuesday_times = @not_calendar.select { |hash| Time.zone.parse(hash["start"]).to_date == @tuesday }.collect do |hash|
        [Time.zone.parse(hash["start"]).hour, Time.zone.parse(hash["end"]).hour]
      end

      expect(@tuesday_times).to eq([[0, 1], [3, 7], [9, 0]])

      # rules for other days should be 12am-12pm
      @other_times = @not_calendar.select { |hash| Time.zone.parse(hash["start"]).to_date != @tuesday }.collect do |hash|
        [Time.zone.parse(hash["start"]).hour, Time.zone.parse(hash["end"]).hour]
      end
      expect(@other_times).to eq([[0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0]])
    end

    it "should build calendar object using adjacent rules across days" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility,
                                      reserve_interval: 60)
      # create rule tue 9 pm - 12 am
      @options = {
        on_mon: false, on_tue: true, on_wed: false, on_thu: false, on_fri: false, on_sat: false, on_sun: false,
        start_hour: 21, start_min: 0, end_hour: 24, end_min: 0, discount_percent: 0
      }

      @rule1 = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?
      # create rule wed 12 am - 9 am
      @options = {
        on_mon: false, on_tue: false, on_wed: true, on_thu: false, on_fri: false, on_sat: false, on_sun: false,
        start_hour: 0, start_min: 0, end_hour: 9, end_min: 0, discount_percent: 0
      }

      @rule2 = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday = Time.current.beginning_of_week(:sunday) + 2.days
      @wednesday = @tuesday + 1.day

      # times should be tue 9 pm - 12 am
      @calendar1 = @rule1.as_calendar_objects
      @calendar1.each do |hash|
        expect(Time.zone.parse(hash["start"])).to eq(@tuesday + 21.hours)
        expect(Time.zone.parse(hash["end"])).to eq(@tuesday + 24.hours)
      end

      # times should be wed 12 am - 9 am
      @calendar2 = @rule2.as_calendar_objects

      @calendar2.each do |hash|
        # .in_time_zone will convert the Date @wedensday to midnight in the Application's timezone
        # + 9.hours will also convert to
        expect(Time.zone.parse(hash["start"])).to eq(@wednesday)
        expect(Time.zone.parse(hash["end"])).to eq(@wednesday + 9.hours)
      end
    end

    it "should build calendar object using start date" do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility)
      # create rule every day from 9 am to 5 pm
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
      assert @rule.valid?

      # set start_date as wednesday
      @wednesday = Time.current.beginning_of_week(:sunday).to_date + 3
      @calendar = @rule.as_calendar_objects(start_date: @wednesday)

      # should start on wednesday
      expect(@calendar.size).to eq(7)
      expect(Time.zone.parse(@calendar[0]["start"]).to_date).to eq(@wednesday)
    end
  end

  context "available_to_user" do
    before :each do
      @facility = FactoryBot.create(:setup_facility)
      @instrument = FactoryBot.create(:instrument,
                                      facility: @facility,
                                      requires_approval: true)
      @rule = @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule))
      @user = FactoryBot.create(:user)
    end

    context "if instrument has no levels" do
      it "should not return a rule if the user is not added" do
        expect(@instrument.schedule_rules.available_to_user(@user)).to be_empty
      end

      it "should return a rule" do
        @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id)
        expect(@instrument.schedule_rules.available_to_user(@user).to_a).to eq([@rule])
      end
    end

    context "if instrument has levels" do
      before :each do
        @restriction_levels = []
        3.times do
          @restriction_levels << FactoryBot.create(:product_access_group, product_id: @instrument.id)
        end
      end

      context "the scheduling rule does not have levels" do
        it "should return a rule if the user is in the group" do
          @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id)
          expect(@instrument.schedule_rules.available_to_user(@user).to_a).to eq([@rule])
        end
      end

      context "the scheduling rule has levels" do
        before :each do
          @rule.product_access_groups = [@restriction_levels[0], @restriction_levels[2]]
          @rule.save!
        end

        it "should return the rule if the user is in the group" do
          @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id, product_access_group_id: @restriction_levels[0])
          expect(@instrument.schedule_rules.available_to_user(@user).to_a).to eq([])
        end

        it "should not return the rule if the user is not in the group" do
          @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id, product_access_group_id: @restriction_levels[1])
          expect(@instrument.schedule_rules.available_to_user(@user)).to be_empty
        end

        it "should not return the rule if the user has no group" do
          @product_user = ProductUser.create(product: @instrument, user: @user, approved_by: @user.id)
          expect(@instrument.schedule_rules.available_to_user(@user)).to be_empty
        end

        it "should return the rule if requires_approval has been set to false" do
          @instrument.update_attributes(requires_approval: false)
          expect(@instrument.available_schedule_rules(@user)).to eq([@rule])
        end
      end
    end
  end
end
