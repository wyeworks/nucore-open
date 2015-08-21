require 'spec_helper'

describe ScheduleRule do
  let(:facility) { create(:facility) }
  let(:facility_account) { facility.facility_accounts.create(attributes_for(:facility_account)) }
  let(:instrument) { create(:instrument, facility: facility, facility_account: facility_account) }

  it "should create using factory" do
    @facility   = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
    @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    @rule.should be_valid
  end

  describe ".unavailable_for_date" do
    context "for an instrument available only from 9 AM to 5 PM" do
      before(:each) do
        instrument.schedule_rules.create(attributes_for(:schedule_rule))
      end

      let(:reservations) { ScheduleRule.unavailable_for_date(instrument, day) }

      shared_examples_for "it generates reservations to cover unavailability" do
        it "returns two dummy reservations" do
          expect(reservations.size).to eq(2)

          reservations.each do |reservation|
            expect(reservation).to be_kind_of(Reservation)
            expect(reservation).to be_blackout
            expect(reservation).not_to be_persisted
          end
        end

        it "reserves midnight to 9 AM as unavailable" do
          expect(reservations.first.reserve_start_at)
            .to eq(day.to_time.change(hour: 0, min: 0))
          expect(reservations.first.reserve_end_at)
            .to eq(day.to_time.change(hour: 9, min: 0))
        end

        it "reserves 5 PM to midnight as unavailable" do
          expect(reservations.last.reserve_start_at)
            .to eq(day.to_time.change(hour: 17, min: 0))
          expect(reservations.last.reserve_end_at)
            .to eq(day.to_time.change(hour: 24, min: 0))
        end
      end

      context "when the 'day' argument is a date" do
        let(:day) { Date.today }

        it_behaves_like "it generates reservations to cover unavailability"
      end

      context "when the 'day' argument is a time" do
        let(:day) { Time.zone.now }

        it_behaves_like "it generates reservations to cover unavailability"
      end
    end
  end

  context "times" do
    it "should not be valid with start hours outside 0-24" do
      should_not allow_value(-1).for(:start_hour)
      should_not allow_value(25).for(:start_hour)
      should allow_value(0).for(:start_hour)
      should allow_value(23).for(:start_hour)
    end

    it "should not be valid with start mins outside 0-59" do
      should_not allow_value(-1).for(:end_min)
      should_not allow_value(60).for(:end_min)
      should allow_value(0).for(:end_min)
      should allow_value(59).for(:end_min)
    end

    it "should allow all day rule" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      @options    = Hash[:start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 0]
      @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule).merge(@options))
      assert @rule.valid?
    end

    it "should not allow end_hour == 24 and end_min != 0" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      @options    = Hash[:start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 1]
      @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule).merge(@options))
      assert @rule.invalid?
      assert_equal ["End time is invalid"], @rule.errors[:base]
    end

    it "should recognize inclusive datetimes" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      @rule       = @instrument.schedule_rules.build(FactoryGirl.attributes_for(:schedule_rule))
      @rule.includes_datetime(DateTime.new(1981, 9, 15, 12, 0, 0)).should == true
    end

    it "should not recognize non-inclusive datetimes" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      @rule       = @instrument.schedule_rules.build(FactoryGirl.attributes_for(:schedule_rule))
      @rule.includes_datetime(DateTime.new(1981, 9, 15, 3, 0, 0)).should == false
    end
  end

  it "should not allow rule conflicts" do
    @facility   = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    assert @rule.valid?

    # not allow rule from 9 am to 5 pm
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 9, :end_hour => 17)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 9 am to 10 am
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:end_hour => 10)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 10 am to 11 am
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 10, :end_hour => 11)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 3 pm to 5 pm
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 15, :end_hour => 17)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 7 am to 10 am
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 7, :end_hour => 10)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 4 pm to 10 pm
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 16, :end_hour => 22)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]

    # not allow rule from 8 am to 8 pm
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 8, :end_hour => 20)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.errors[:base]
  end

  it "should allow adjacent rules" do
    @facility   = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    assert @rule.valid?

    # allow rule from 7 am to 9 am
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 7, :end_hour => 9)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?

    # allow rule from 5 pm to 12am
    @options    = FactoryGirl.attributes_for(:schedule_rule).merge(:start_hour => 17, :end_hour => 24)
    @rule1      = @instrument.schedule_rules.create(@options)
    assert @rule1.valid?
  end

  # it "should not conflict with existing reservation" do
  #   @facility   = FactoryGirl.create(:facility)
  #   @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
  #   @instrument = @facility.instruments.create(FactoryGirl.attributes_for(:instrument, :facility_account_id => @facility_account.id))
  #   # create rule every day from 9 am to 5 pm
  #   @rule1      = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
  #   assert @rule1.valid?
  #
  #   # start/end at the exact same time
  #   @rule2      = @instrument.schedule_rules.build(FactoryGirl.attributes_for(:schedule_rule))
  #   @rule2.should_not be_valid
  #
  #   # start/end one hour before valid rule, but times overlap
  #   @rule2.start_hour = @rule2.start_hour - 1
  #   @rule2.end_hour   = @rule2.end_hour - 1
  #   @rule2.should_not be_valid
  # end

  it "should not be valid with an end time after the start time" do
    @facility   = FactoryGirl.create(:facility)
    @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
    @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
    # create rule every day from 9 am to 5 pm
    @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
    assert @rule.valid?

    @rule.start_hour = 9
    @rule.start_min = 00
    @rule.end_hour = 9
    @rule.end_min = 00
    @rule.should_not be_valid

    @rule.end_hour = 8
    @rule.end_min = 20
    @rule.should_not be_valid
  end

  context "calendar object" do
    it "should build calendar object for 9-5 rule every day" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      # create rule every day from 9 am to 5 pm
      @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      assert @rule.valid?

      # find past sunday, and build calendar object
      @sunday   = ScheduleRule.sunday_last
      @calendar = @rule.as_calendar_object

      # each title should be the same
      @calendar.each do |hash|
        hash["title"].should == "Interval: #{@instrument.reserve_interval} minute"
        hash["allDay"].should == false
      end

      # days should start with this past sunday and end next saturday
      @calendar.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday+i.days} 9:00")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday+i.days} 17:00")
      end

      # build unavailable rules from the available rules collection
      @not_available = ScheduleRule.unavailable(@rule)
      @not_available.size.should == 14
      # should mark each rule as unavailable
      assert_equal true, @not_available.first.unavailable
      @not_calendar  = @not_available.collect{ |na| na.as_calendar_object }.flatten

      # days should be same as above
      # even times should be 12 am to 9 am
      # odd times should be 5 pm to 12 pm
      even = (0..@not_available.size).select{ |i| i.even? }
      odd  = (0..@not_available.size).select{ |i| i.odd? }

      even.collect{ |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday+i.days}")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday+i.days} 9:00")
      end

      odd.collect{ |i| @not_calendar.values_at(i) }.flatten.compact.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == Time.zone.parse("#{@sunday + i.days} 17:00")
        Time.zone.parse(hash['end']).should == Time.zone.parse("#{@sunday + (i+1).days}")
      end

      # should set calendar objects title to ''
      @not_calendar.each do |hash|
        hash['title'].should == ''
      end
    end

    it "should build calendar object using multiple rules on the same day" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :reserve_interval => 60,
                                        :facility_account => @facility_account)
      # create rule tue 1 am - 3 am
      @options = {
        :on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
        :start_hour => 1, :start_min => 0, :end_hour => 3, :end_min => 0, :discount_percent => 0
      }

      @rule1      = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?

      # create rule tue 7 am - 9 am
      @options = {
        :on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
        :start_hour => 7, :start_min => 0, :end_hour => 9, :end_min => 0, :discount_percent => 0
      }

      @rule2      = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday    = ScheduleRule.sunday_last + 2.days

      # times should be tue 1 am - 3 am
      @calendar1  = @rule1.as_calendar_object
      @calendar1.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 1.hour)
        Time.zone.parse(hash['end']).should == (@tuesday + 3.hours)
      end

      # times should be tue 7 am - 9 am
      @calendar2  = @rule2.as_calendar_object
      @calendar2.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 7.hours)
        Time.zone.parse(hash['end']).should == (@tuesday + 9.hours)
      end

      # build not available rules from the available rules collection, 3 for tue and 1 each for rest of days
      @not_available = ScheduleRule.unavailable([@rule1, @rule2])
      @not_available.size.should == 9
      @not_calendar  = @not_available.collect{ |na| na.as_calendar_object }.flatten

      # rules for tuesday should be 12am-1am, 3am-7am, 9pm-12pm
      @tuesday_times = @not_calendar.select{ |hash| Time.zone.parse(hash['start']).to_date == @tuesday }.collect do |hash|
        [Time.zone.parse(hash['start']).hour, Time.zone.parse(hash['end']).hour]
      end
      @tuesday_times.should == [[0,1], [3,7], [9,0]]

      # rules for other days should be 12am-12pm
      @other_times = @not_calendar.select{ |hash| Time.zone.parse(hash['start']).to_date != @tuesday }.collect do |hash|
        [Time.zone.parse(hash['start']).hour, Time.zone.parse(hash['end']).hour]
      end
      @other_times.should == [[0,0], [0,0], [0,0], [0,0], [0,0], [0,0]]
    end

    it "should build calendar object using adjacent rules across days" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :reserve_interval => 60,
                                        :facility_account => @facility_account)
      # create rule tue 9 pm - 12 am
      @options = {
        :on_mon => false, :on_tue => true, :on_wed => false, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
        :start_hour => 21, :start_min => 0, :end_hour => 24, :end_min => 0, :discount_percent => 0
      }

      @rule1      = @instrument.schedule_rules.create(@options)
      assert @rule1.valid?
      # create rule wed 12 am - 9 am
      @options = {
        :on_mon => false, :on_tue => false, :on_wed => true, :on_thu => false, :on_fri => false, :on_sat => false, :on_sun => false,
        :start_hour => 0, :start_min => 0, :end_hour => 9, :end_min => 0, :discount_percent => 0
      }

      @rule2      = @instrument.schedule_rules.create(@options)
      assert @rule2.valid?

      # find past tuesday, and build calendar objects
      @tuesday    = ScheduleRule.sunday_last + 2.days
      @wednesday  = @tuesday + 1.day

      # times should be tue 9 pm - 12 am
      @calendar1  = @rule1.as_calendar_object
      @calendar1.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@tuesday + 21.hours)
        Time.zone.parse(hash['end']).should == (@tuesday + 24.hours)
      end

      # times should be tue 12 am - 9 am
      @calendar2  = @rule2.as_calendar_object
      @calendar2.each_with_index do |hash, i|
        Time.zone.parse(hash['start']).should == (@wednesday + 0.hours)
        Time.zone.parse(hash['end']).should == (@wednesday + 9.hours)
      end
    end

    it "should build calendar object using start date" do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account)
      # create rule every day from 9 am to 5 pm
      @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      assert @rule.valid?

      # set start_date as wednesday
      @wednesday  = ScheduleRule.sunday_last + 3.days
      @calendar   = @rule.as_calendar_object(:start_date => @wednesday)

      # should start on wednesday
      @calendar.size.should == 7
      Time.zone.parse(@calendar[0]['start']).to_date.should == @wednesday
    end
  end

  context 'available_to_user' do
    before :each do
      @facility   = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument = FactoryGirl.create(:instrument,
                                        :facility => @facility,
                                        :facility_account => @facility_account,
                                        :requires_approval => true)
      @rule       = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      @user = FactoryGirl.create(:user)
    end

    context 'if instrument has no levels' do
      it 'should not return a rule if the user is not added' do
        @instrument.schedule_rules.available_to_user(@user).should be_empty
      end

      it 'should return a rule' do
        @product_user = ProductUser.create({:product => @instrument, :user => @user, :approved_by => @user.id})
        @instrument.schedule_rules.available_to_user(@user).to_a.should == [@rule]
      end
    end

    context 'if instrument has levels' do
      before :each do
        @restriction_levels = []
        3.times do
          @restriction_levels << FactoryGirl.create(:product_access_group, :product_id => @instrument.id)
        end
      end

      context 'the scheduling rule does not have levels' do
        it 'should return a rule if the user is in the group' do
          @product_user = ProductUser.create({:product => @instrument, :user => @user, :approved_by => @user.id})
          @instrument.schedule_rules.available_to_user(@user).to_a.should == [@rule]
        end
      end

      context 'the scheduling rule has levels' do
        before :each do
          @rule.product_access_groups = [@restriction_levels[0], @restriction_levels[2]]
          @rule.save!
        end

        it 'should return the rule if the user is in the group' do
          @product_user = ProductUser.create({:product => @instrument, :user => @user, :approved_by => @user.id, :product_access_group_id => @restriction_levels[0]})
          @instrument.schedule_rules.available_to_user(@user).to_a.should == []
        end

        it 'should not return the rule if the user is not in the group' do
          @product_user = ProductUser.create({:product => @instrument, :user => @user, :approved_by => @user.id, :product_access_group_id => @restriction_levels[1]})
          @instrument.schedule_rules.available_to_user(@user).should be_empty
        end

        it 'should not return the rule if the user has no group' do
          @product_user = ProductUser.create({:product => @instrument, :user => @user, :approved_by => @user.id})
          @instrument.schedule_rules.available_to_user(@user).should be_empty
        end

        it 'should return the rule if requires_approval has been set to false' do
          @instrument.update_attributes(:requires_approval => false)
          @instrument.available_schedule_rules(@user).should == [@rule]
        end
      end
    end
  end
end
