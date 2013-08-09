require 'spec_helper'
require 'product_shared_examples'

describe Instrument do
  it_should_behave_like 'ReservationProduct', :instrument

  context "factory" do
    it "should create using factory" do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account)
      @instrument.should be_valid
      @instrument.type.should == 'Instrument'
    end
  end

  [ :min_reserve_mins, :max_reserve_mins, :auto_cancel_mins ].each do |attr|
    it "should require #{attr} to be >= 0 and integers only" do
      should allow_value(0).for(attr)
      should_not allow_value(-1).for(attr)
      should_not allow_value(5.0).for(attr)
    end
  end

  describe 'shared schedules' do
    context 'default schedule' do
      before :each do
        @facility = FactoryGirl.create(:facility)
        @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      end

      it 'should create a default schedule' do
        @instrument = FactoryGirl.build(:instrument,
                                          :facility => @facility,
                                          :facility_account => @facility_account,
                                          :schedule => nil)
        @instrument.schedule.should be_nil
        @instrument.save.should be_true
        @instrument.schedule.should be
      end

      it 'should not create a new schedule when defined' do
        @schedule = FactoryGirl.create(:schedule, :facility => @facility)
        @instrument = FactoryGirl.build(:instrument,
                                          :facility => @facility,
                                          :facility_account => @facility_account,
                                          :schedule => @schedule)
        @instrument.schedule.should be
        @instrument.save.should be_true
        @instrument.schedule.should == @schedule
      end
    end

    describe 'schedule_sharing?' do
      context 'one instrument' do
        before :each do
          @facility = FactoryGirl.create(:setup_facility)
          @instrument = FactoryGirl.create(:setup_instrument, :facility => @facility)
        end

        it 'should not be sharing' do
          @instrument.should_not be_schedule_sharing
        end

        context 'two instruments' do
          before :each do
            @instrument2 = FactoryGirl.create(:setup_instrument, :facility => @facility, :schedule => @instrument.schedule)
          end

          it 'should be sharing' do
            @instrument.should be_schedule_sharing
          end
        end
      end
    end

    describe 'name updating' do
      before :each do
        @instrument = setup_instrument(:schedule => nil)
        @instrument2 = FactoryGirl.create(:setup_instrument, :schedule => @instrument.schedule)
        assert @instrument.schedule == @instrument2.schedule
      end

      it "should update the schedule's name when updating the primary instrument's name" do
        @instrument.update_attributes(:name => 'New Name')
        @instrument.schedule.reload.name.should == 'New Name Schedule'
      end

      it 'should not call update_schedule_name if name did not change' do
        @instrument.should_receive(:update_schedule_name).never
        @instrument.update_attributes(:description => 'a description')
      end

      it "should not update the schedule's name when updating the secondary instrument" do
        @instrument2.update_attributes(:name => 'New Name')
        @instrument2.schedule.reload.name.should == "#{@instrument.name} Schedule"
      end
    end
  end


  context "updating nested relay" do
    before :each do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument       = FactoryGirl.create(:instrument,
                                              :facility => @facility,
                                              :facility_account => @facility_account,
                                              :no_relay => true)
    end

    context "existing type: 'timer' (Timer without relay)" do
      before :each do
        @instrument.relay = RelayDummy.new(:instrument => @instrument)
        @instrument.relay.save!
        @instrument.control_mechanism.should == 'timer'
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => {:type => 'RelaySynaccessRevA'})
          end

          it "should fail" do
            @updated.should be_false
          end

          it "should have errors" do
            @instrument.errors.full_messages.should_not == []
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => FactoryGirl.attributes_for(:relay))
          end

          it "should succeed" do
            @updated.should be_true
          end

          it "should have no errors" do
            @instrument.errors.full_messages.should == []
          end

          it "should have control mechanism of relay" do
            @instrument.reload.control_mechanism.should == 'relay'
          end
        end
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'manual')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "should have a control_mechanism of manual" do
          @instrument.reload.control_mechanism.should == 'manual'
        end

        it "should destroy the relay" do
          @instrument.reload.relay.should be_nil
        end
      end
    end

    context "existing type: RelaySynaccessA" do
      before :each do
        FactoryGirl.create(:relay, :instrument_id => @instrument.id)
        @instrument.reload.control_mechanism.should == 'relay'
      end

      context "update with new control_mechanism: 'manual' (Reservation Only)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'manual')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "should have a control_mechanism of manual" do
          @instrument.reload.control_mechanism.should == 'manual'
        end

        it "should destroy the relay" do
          @instrument.reload.relay.should be_nil
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'timer')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "control mechanism should be a timer" do
          @instrument.reload.control_mechanism.should == 'timer'
        end
      end
    end

    context "existing type: manual 'Reservation Only'" do
      before :each do
        @instrument.relay.destroy if @instrument.relay
        @instrument.reload.control_mechanism.should == Relay::CONTROL_MECHANISMS[:manual]
      end

      context "update with new control_mechanism: 'relay' (Timer with relay)" do
        context "when validations not met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => {:type => 'RelaySynaccessRevA'})
          end

          it "should fail" do
            @updated.should be_false
          end

          it "should have errors" do
            @instrument.errors.full_messages.should_not == []
          end
        end

        context "when validations met" do
          before :each do
            @updated = @instrument.update_attributes(:control_mechanism => "relay", :relay_attributes => FactoryGirl.attributes_for(:relay))
          end
          it "should succeed" do
            @updated.should be_true
          end

          it "should have no errors" do
            @instrument.errors.full_messages.should == []
          end

          it "should have control mechanism of relay" do
            @instrument.reload.control_mechanism.should == 'relay'
          end
        end
      end

      context "update with new control_mechanism: 'timer' (Timer without relay)" do
        before :each do
          @updated = @instrument.update_attributes(:control_mechanism => 'timer')
        end

        it "should succeed" do
          @updated.should be_true
        end

        it "control mechanism should be a timer" do
          @instrument.reload.control_mechanism.should == 'timer'
        end
      end
    end
  end

  context "reservations with schedule rules from 9 am to 5 pm every day, with 60 minute durations" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account,
                                      :min_reserve_mins => 60,
                                      :max_reserve_mins => 60)
      assert @instrument.valid?
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule             = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      assert @rule.valid?
      Reservation.any_instance.stub(:admin?).and_return(false)
    end

    it "should not allow reservation in the past" do
      @reservation = @instrument.reservations.create(:reserve_start_at => Time.zone.now - 1.hour, :reserve_end_at => Time.zone.now)
      assert @reservation.errors[:reserve_start_at]
    end

    it "should not allow 1 hour reservation for a time not between 9 and 5" do
      # 8 am - 9 am
      @start       = Time.zone.now.end_of_day + 1.second + 8.hours
      @reservation = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start + 1.hour)
      assert @reservation.errors[:base]
    end

    it "should not allow a 2 hour reservation" do
      # 8 am - 10 pam
      @start       = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start + 2.hours)
      assert @reservation.errors[:base]
    end

    it "should allow 1 hour reservations between 9 and 5" do
      # 9 am - 10 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # should allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+1.hour, :reserve_end_at => @start+2.hours)
      assert @reservation2.valid?
      # should find 2 upcoming reservations when both are in the future
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming
      # should find 2 upcoming reservations when both are in the future or happening now
      assert_equal [@reservation1, @reservation2], @instrument.reservations.upcoming(@start+1.minute)
      # should find 1 upcoming when 1 is in the past
      assert_equal [@reservation2], @instrument.reservations.upcoming(@start+1.hour)
    end

    it "should allow 1 hour reservations between 9 and 5, using duration_value, duration_unit virtual attribute" do
      # 9 am - 10 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation1.valid?
      assert_equal 60, @reservation1.reload.duration_mins
    end

    it "should not allow overlapping reservations between 9 and 5" do
      # 10 am - 11 am
      @start        = Time.zone.now.end_of_day + 1.second + 10.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # not allow 10 am - 11 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 10:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-30.minutes, :reserve_end_at => @start+30.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 10:30 am, using reserve_start_date, reserve_start_hour, reserve_start_min, reserve_start_meridian
      @options      = {:reserve_start_date => @start.to_s, :reserve_start_hour => '9', :reserve_start_min => '30',
                       :reserve_start_meridian => 'am', :duration_value => '60', :duration_unit => 'minutes'}
      @reservation2 = @instrument.reservations.create(@options)
      @reservation2.errors[:base].should_not be_empty
      # not allow 9:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-30.minutes, :reserve_end_at => @start+90.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 10:30 am - 10:45 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+30.minutes, :reserve_end_at => @start+45.minutes)
      @reservation2.errors[:base].should_not be_empty
      # not allow 10:30 am - 11:30 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start+30.minutes, :reserve_end_at => @start+90.minutes)
      @reservation2.errors[:base].should_not be_empty
    end

    it "should allow adjacent reservations" do
      # 10 am - 11 am
      @start        = Time.zone.now.end_of_day + 1.second + 10.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :reserve_end_at => @start+1.hour)
      assert @reservation1.valid?
      # should allow 9 am - 10 am
      @reservation2 = @instrument.reservations.create(:reserve_start_at => @start-1.hour, :reserve_end_at => @start)
      assert @reservation2.valid?
      # should allow 11 am - 12 pm
      @reservation3 = @instrument.reservations.create(:reserve_start_at => @start+1.hour, :reserve_end_at => @start+2.hours)
      assert @reservation3.valid?
    end
  end

  context "next available reservation based on schedule rules" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account,
                                      :min_reserve_mins => 60,
                                      :max_reserve_mins => 60)
      assert @instrument.valid?
    end

    it "should find next available reservation with 60 minute interval rule, without any pending reservations" do
      # add rule, available every day from 9 to 5, 60 minutes duration/interval
      @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      assert @rule.valid?
      # stub so today at 9 am is not in the future
      Reservation.any_instance.stub(:in_the_future).and_return(true)
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      # find next reservation after 9:01 am today at 10 am today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+9.hours+1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 4:01 pm today at 9 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+16.hours+1.minute)
      assert_equal (Time.zone.now+1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
    end

    it "should find next available reservation with 5 minute interval rule, without any pending reservations" do
      # add rule, available every day from 9 to 5, 5 minute duration/interval
      @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, :duration_mins => 5))
      assert @rule.valid?
      # stub so today at 9 am is not in the future
      Reservation.any_instance.stub(:in_the_future).and_return(true)
      # find next reservation after 12 am at 9 am
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 0, @next_reservation.reserve_start_at.min
      # find next reservation after 9:01 am today at 9:05 am today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+9.hours+1.minute)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 9, @next_reservation.reserve_start_at.hour
      assert_equal 5, @next_reservation.reserve_start_at.min
      # find next reservation after 3:45 pm today at 3:45 pm today
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.beginning_of_day+15.hours+45.minutes)
      assert_equal Time.zone.now.day, @next_reservation.reserve_start_at.day
      assert_equal 15, @next_reservation.reserve_start_at.hour
      assert_equal 45, @next_reservation.reserve_start_at.min
    end

    it "should find next available reservation with pending reservations" do
      # add rule, available every day from 9 to 5, 60 minutes duration
      @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule))
      assert @rule.valid?
      # add reservation for tomorrow morning at 9 am
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation1 = @instrument.reservations.create(:reserve_start_at => @start, :duration_value => 60, :duration_unit => 'minutes')
      assert @reservation1.valid?
      # find next reservation after 12 am tomorrow at 10 am tomorrow
      @next_reservation = @instrument.next_available_reservation(after = Time.zone.now.end_of_day+1.second)
      assert_equal (Time.zone.now+1.day).day, @next_reservation.reserve_start_at.day
      assert_equal 10, @next_reservation.reserve_start_at.hour
    end
  end

  context "available hours based on schedule rules" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account,
                                      :min_reserve_mins => 60,
                                      :max_reserve_mins => 60)
      assert @instrument.valid?
    end

    it 'should default to 0 and 23 if no schedule rules' do
      @instrument.first_available_hour.should == 0
      @instrument.last_available_hour.should == 23
    end

    context 'with a mon-friday rule from 9-5' do
      before :each do
        # add rule, monday-friday from 9 to 5, 60 minutes duration
        @rule = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:schedule_rule, :on_sun => false, :on_sat => false))
        assert @rule.valid?
      end

      it "should have first avail hour at 9 am, last avail hour at 4 pm" do
        @instrument.first_available_hour.should == 9
        @instrument.last_available_hour.should == 16
      end

      context 'with a weekend reservation going from 8-6' do
        before :each do
          @rule2 = @instrument.schedule_rules.create(FactoryGirl.attributes_for(:weekend_schedule_rule,
                                                                  :start_hour => 8,
                                                                  :end_hour => 18))
          assert @rule2.valid?
        end

        it "should have first avail hour at 8 am, last avail hour at 6 pm" do
          @instrument.first_available_hour.should == 8
          @instrument.last_available_hour.should == 17
        end
      end
    end
  end

  context "last reserve dates, days from now" do
    before(:each) do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @price_group      = @facility.price_groups.create(FactoryGirl.attributes_for(:price_group))
      # create instrument, min reserve time is 60 minutes, max is 60 minutes
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account,
                                      :min_reserve_mins => 60,
                                      :max_reserve_mins => 60)
      @price_group_product=FactoryGirl.create(:price_group_product, :product => @instrument, :price_group => @price_group)
      assert @instrument.valid?

      # create price policy with default window of 1 day
      @price_policy     = @instrument.instrument_price_policies.create(FactoryGirl.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id))
    end

    it "should have last_reserve_date == tomorrow, last_reserve_days_from_now == 1 when window is 1" do
      @instrument.price_group_products.each{|pgp| pgp.update_attributes(:reservation_window => 1) }
      assert_equal Time.zone.now.to_date + 1.day, @instrument.reload.last_reserve_date
      assert_equal 1, @instrument.max_reservation_window
    end

    it "should use max window of all price polices to calculate dates" do
      # create price policy with window of 15 days
      @price_group_product.reservation_window=15
      assert @price_group_product.save
      @options       = FactoryGirl.attributes_for(:instrument_price_policy).update(:price_group_id => @price_group.id)
      @price_policy2 = @instrument.instrument_price_policies.new(@options)
      @price_policy2.save(:validate => false) # save without validations
      assert_equal 15, @instrument.max_reservation_window
      assert_equal (Time.zone.now+15.days).to_date, @instrument.last_reserve_date
    end
  end

  context 'can_purchase?' do
    before :each do
      @facility         = FactoryGirl.create(:facility)
      @facility_account = @facility.facility_accounts.create(FactoryGirl.attributes_for(:facility_account))
      @instrument       = FactoryGirl.create(:instrument,
                                      :facility => @facility,
                                      :facility_account => @facility_account)
      @price_group = FactoryGirl.create(:price_group, :facility => @facility)
      @user = FactoryGirl.create(:user)
      @price_group_member = FactoryGirl.create(:user_price_group_member, :user => @user, :price_group => @price_group)
      @user.reload
      @user_price_policy_ids = @user.price_groups.map(&:id)
      @price_policy = FactoryGirl.create(:instrument_price_policy, :product => @instrument, :price_group => @price_group)
      #TODO remove this line
      FactoryGirl.create(:price_group_product, :price_group => @price_group, :product => @instrument)
    end

    it 'should be purchasable if there are schedule rules' do
      @schedule_rule = FactoryGirl.create(:schedule_rule, :instrument => @instrument)
      @instrument.reload
      @instrument.should be_can_purchase(@user_price_policy_ids)
    end

    it 'should not be purchasable if there are no schedule rules' do
      @instrument.should_not be_can_purchase(@user_price_policy_ids)
    end

    context 'with schedule rules' do
      before :each do
        @schedule_rule = FactoryGirl.create(:schedule_rule, :instrument => @instrument)
        @instrument.reload
      end
      it 'should be purchasable if there are schedule rules' do
        @instrument.should be_can_purchase(@user_price_policy_ids)
      end

      context 'with no price policies at all' do
        before :each do
          @instrument.price_policies.clear
        end
        it 'should have no price policies' do
          @instrument.price_policies.should be_empty
        end
        it 'should not be purchasable' do
          @instrument.should_not be_can_purchase(@user_price_policy_ids)
        end
      end

      context 'with current price polices, but not for user' do
        before :each do
          @user.price_group_members.delete(@price_group_member)
        end
        it 'should be set up right' do
          @instrument.price_policies.current.should_not be_empty
          @user.price_groups.should_not include @price_group
        end

        it 'should not be purchasable' do
          @instrument.should_not be_can_purchase(@user.price_groups.map(&:id))
        end
      end

      context 'with expired price policies for user' do
        before :each do
          @price_policy.update_attributes(:start_date => 10.days.ago, :expire_date => 1.day.ago)
        end

        it 'should be set up right' do
          @instrument.price_policies.current.should be_empty
        end

        it 'should be purchasable' do
          @instrument.can_purchase?(@user_price_policy_ids).should be_true
          @instrument.should be_can_purchase(@user_price_policy_ids)
        end
      end

      context 'with expired price policies, but not for user' do
        before :each do
          @user.price_group_members.delete(@price_group_member)
          @price_policy.update_attributes(:start_date => 10.days.ago, :expire_date => 1.day.ago)
        end

        it 'should be set up right' do
          @instrument.price_policies.current.should be_empty
          @instrument.price_policies.should_not be_empty
          @user.price_groups.should_not include @price_groups
        end

        it 'should not be purchasable' do
          @instrument.should_not be_can_purchase(@user.price_groups.map(&:id))
        end

      end
    end

  end

  describe 'available?' do
    subject(:instrument) { FactoryGirl.create :setup_instrument }

    it { should be_available }

    context 'there is not a current schedule rule' do
      before :each do
        instrument.schedule_rules.destroy_all
      end

      it { should_not be_available }
    end

    context 'reservation only instrument' do
      context 'with a current reservation' do
        let!(:reservation) { FactoryGirl.create :purchased_reservation,
                :reserve_start_at => 30.minutes.ago,
                :reserve_end_at   => 30.minutes.from_now,
                :product => instrument }

        it { should_not be_available }

        context 'but it was cancelled' do
          let(:user) { FactoryGirl.build :user }
          before :each do
            Timecop.travel(60.minutes.ago) do
              reservation.order_detail.update_order_status! user, OrderStatus.cancelled.first
              reservation.should be_cancelled
            end
          end

          it { should be_available }
        end
      end

      context 'with no minimum reservation' do
        before :each do
          instrument.update_attributes!(:min_reserve_mins => nil)
        end

        it { should be_available }
      end
    end

    context 'instrument with timer' do
      before :each do
        instrument.update_attributes!(:control_mechanism => 'manual')
      end

      context 'with a current reservation' do
        let!(:reservation) { FactoryGirl.create :purchased_reservation,
                :reserve_start_at => 30.minutes.ago,
                :reserve_end_at   => 30.minutes.from_now,
                :product => instrument }

        context 'and is started' do
          before :each do
            reservation.update_attributes(:reserved_by_admin => true,
                                          :actual_start_at => 30.minutes.ago)
          end

          it { should_not be_available }

          context 'but it was ended already' do
            before :each do
              reservation.update_attributes(:reserved_by_admin => true,
                                            :actual_end_at => 10.minutes.ago)
            end

            it { should be_available }
          end
        end
      end
    end
  end

end
