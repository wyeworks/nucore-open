# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ReservationsController do
  include DateHelper

  let(:facility) { @authable }
  let(:instrument) { @instrument }
  let(:order) { @order }
  let(:order_detail) { order.order_details.first }
  let(:reservation) { @reservation }

  render_views

  before(:all) { create_users }

  before(:each) do
    setup_instrument
    setup_user_for_purchase(@guest, @price_group)

    @order = @guest.orders.create(FactoryBot.attributes_for(:order, created_by: @guest.id, account: @account))
    @order.add(@instrument, 1)
    @order_detail = @order.order_details.first
    assert @order_detail.persisted?

    @params = { order_id: @order.id, order_detail_id: @order_detail.id }
    create(:account_price_group_member, account: @account, price_group: @price_group)
  end

  shared_examples_for "it can handle having its order_detail removed" do
    context "when the order_detail has been removed" do
      before do
        @order.order_details.destroy_all
        sign_in @purchaser
        do_request
      end

      it "redirects to the facility's landing page with an error message", :aggregate_failures do
        expect(flash[:error]).to include("has been removed from your cart")
        expect(response).to redirect_to(facility_path(facility))
      end
    end
  end

  describe "GET #index" do
    before(:each) do
      allow(order).to receive(:cart_valid?).and_return(true)
      order.validate_order!
      order.purchase!

      @method = :xhr
      @action = :index
      @params.merge!(instrument_id: instrument.url_name, facility_id: facility.url_name)
    end

    it_should_allow_all facility_users do
      expect(assigns[:facility]).to eq(facility)
      expect(assigns[:instrument]).to eq(instrument)
    end

    describe "start/stop parameters" do
      let(:start_range) { Time.zone.local(2018, 5, 15, 12, 13) }
      let(:end_range) { start_range + 1.week }

      it "supports iso8601 parameters" do
        @params[:start] = start_range.iso8601
        @params[:end] = end_range.iso8601
        do_request
        expect(assigns(:start_at)).to eq(start_range)
        expect(assigns(:end_at)).to eq(end_range)
      end

      it "supports unix timestamps" do
        @params[:start] = start_range.to_i
        @params[:end] = end_range.to_i
        do_request
        expect(assigns(:start_at)).to eq(start_range)
        expect(assigns(:end_at)).to eq(end_range)
      end

      it "defaults to today with no parameters" do
        do_request
        expect(assigns(:start_at)).to eq(Time.current)
        expect(assigns(:end_at)).to eq(Time.current.end_of_day)
      end

      it "defaults to the end of day with missing end param" do
        @params[:start] = start_range.iso8601
        do_request
        expect(assigns(:start_at)).to eq(start_range)
        expect(assigns(:end_at)).to eq(start_range.end_of_day)
      end
    end

    context "schedule rules" do
      let(:now) { Time.current }

      before(:each) do
        sign_in @guest
        @params.merge!(start: now.iso8601)
      end

      context "when end is not set" do
        it "sets the end to end_of_day of the start time" do
          do_request
          expect(assigns[:end_at]).to match_date(now.end_of_day)
        end
      end

      context "when a reservation exists for today" do
        let!(:reservation) do
          instrument.reservations.create(
            reserve_start_at: now,
            order_detail: order_detail,
            duration_mins: 60,
            split_times: true,
          )
        end

        before { do_request }

        it { expect(assigns[:reservations]).to match_array([reservation]) }
      end

      context "when reservations exist before the start date" do
        let!(:reservation) do
          instrument.reservations.create(reserve_start_at: now - 1.day,
                                         order_detail: order_detail,
                                         duration_mins: 60,
                                         split_times: true)
        end

        before { do_request }

        it { expect(assigns[:reservations]).not_to include(reservation) }
      end

      context "when reservations exist after the end date" do
        let!(:reservation) do
          instrument.reservations.create(reserve_start_at: now + 3.days,
                                         order_detail: order_detail,
                                         duration_mins: 60,
                                         split_times: true)
        end

        before(:each) do
          @params[:end] = now + 2.days
          do_request
        end

        it { expect(assigns[:reservations]).not_to include(reservation) }
      end

      context "when it's a month view" do
        before(:each) do
          @params[:start] = 1.day.ago.iso8601
          @params[:end] = 30.days.from_now.iso8601
          do_request
        end

        it { expect(assigns[:unavailable]).to be_blank }
      end

      context "schedule rules" do
        let(:restriction_level) { FactoryBot.create(:product_access_group, product_id: instrument.id) }

        before(:each) do
          instrument.update_attributes(requires_approval: true)
          @rule.product_access_groups = [restriction_level]
          @rule.save!
        end

        context "when not part of a group" do
          before { do_request }

          it { expect(assigns[:rules]).to be_empty }
        end

        context "when part of a group" do
          before do
            ProductUser.create(
              product: instrument,
              user: @guest,
              approved_by: @director.id,
              product_access_group: restriction_level,
            )

            do_request
          end

          it { expect(assigns[:rules]).to match_array([@rule]) }
        end

        context "as admin" do
          before(:each) do
            maybe_grant_always_sign_in :director
            do_request
          end

          it "contains all schedule rules" do
            expect(assigns[:rules]).to match_array([@rule])
          end
        end
      end
    end

    describe "shared scheduling" do
      let(:instrument2) {  FactoryBot.create(:setup_instrument, facility: facility, schedule: instrument.schedule) }
      let(:reservation1) { FactoryBot.create(:purchased_reservation, product: instrument) }
      let(:reservation2) do
        FactoryBot.create(:purchased_reservation,
                          product: instrument2,
                          reserve_start_at: reservation1.reserve_end_at) # Immediately after reservation1
      end
      let(:reservations) { [reservation1, reservation2] }

      before(:each) do
        expect(reservation1).to be_valid
        expect(reservation2).to be_valid
        @params[:start] = 1.day.from_now.iso8601
        sign_in @admin
        do_request
      end

      it "includes instrument1 and instrument2 reservations" do
        expect(assigns(:reservations)).to match_array(reservations)
      end
    end

    describe "showing details" do
      describe "as a guest" do
        before { sign_in @guest }

        it "defaults to false" do
          do_request
          expect(assigns(:show_details)).to be_falsy
        end

        it "is false even if I request it and the instrument is not configured to show it" do
          instrument.update!(show_details: false)
          @params[:with_details] = "true"
          do_request

          expect(assigns(:show_details)).to be_falsy
        end

        it "is true if I request details and it is not configured" do
          instrument.update!(show_details: true)
          @params[:with_details] = "true"
          do_request
          expect(assigns(:show_details)).to be_truthy
        end
      end

      describe "as a facility staff" do
        before { maybe_grant_always_sign_in :staff }

        it "is falsy if I don't request details" do
          do_request
          expect(assigns(:show_details)).to be_falsy
        end

        it "is true if I request details" do
          @params[:with_details] = "true"
          do_request

          expect(assigns(:show_details)).to be_truthy
        end

        it "is falsy if I request with the string false" do
          @params[:with_details] = "false"
          do_request

          expect(assigns(:show_details)).to be_falsy
        end
      end
    end
  end

  context "list" do
    before :each do
      @method = :get
      @action = :list
      @params = {}
    end

    it "should redirect to default view" do
      maybe_grant_always_sign_in(:staff)
      @params[:status] = "junk"
      do_request
      is_expected.to redirect_to "/reservations/upcoming"
    end

    context "upcoming" do
      before :each do
        @params = { status: "upcoming" }
        @upcoming = FactoryBot.create(:purchased_reservation, product: @instrument)
        @in_progress = FactoryBot.create(:purchased_reservation, product: @instrument, reserve_start_at: Time.zone.now, reserve_end_at: 1.hour.from_now)
        @in_progress.update_attributes!(actual_start_at: Time.zone.now)
        [@in_progress, @upcoming].each { |res| res.order_detail.order.update_attributes!(user: @staff) }
      end

      it_should_require_login

      it_should_allow :staff do
        expect(assigns(:available_statuses).size).to eq(2)
        expect(assigns(:status)).to eq(assigns(:available_statuses).first)
        expect(assigns(:order_details).map(&:id)).to match_array([@in_progress.order_detail, @upcoming.order_detail].map(&:id))
        expect(assigns(:active_tab)).to eq("reservations")
        is_expected.to render_template("list")
      end

      context "notices" do
        before :each do
          sign_in @staff
        end

        it "should have message if you can switch on" do
          allow_any_instance_of(Reservation).to receive(:can_switch_instrument_on?).and_return(true)
          do_request
          expect(response.body).to include I18n.t("reservations.notices.can_switch_on", reservation: @upcoming)
        end

        it "should have message if you can switch off" do
          allow_any_instance_of(Reservation).to receive(:can_switch_instrument_off?).and_return(true)
          do_request
          expect(response.body).to include I18n.t("reservations.notices.can_switch_off", reservation: @upcoming)
        end

        it "should have a message for todays reservations" do
          @upcoming.update_attributes(reserve_start_at: 1.hour.from_now, reserve_end_at: 2.hours.from_now)
          tomorrow_reservation = FactoryBot.create(:purchased_reservation, product: @instrument, reserve_start_at: 1.day.from_now)
          tomorrow_reservation.order_detail.order.update_attributes(user: @staff)
          do_request
          expect(response.body).to include I18n.t("reservations.notices.upcoming", reservation: @upcoming)
          expect(response.body).to_not include I18n.t("reservations.notices.upcoming", reservation: @tomorrow)
        end

        it "should not have an upcoming message for a canceled reservation" do
          @upcoming.update_attributes(reserve_start_at: 1.hour.from_now, reserve_end_at: 2.hours.from_now)
          @upcoming.order_detail.update_order_status!(@staff, OrderStatus.canceled)
          do_request
          expect(response.body).to_not include I18n.t("reservations.notices.upcoming", reservation: @upcoming)
        end

      end

      context "moving forward" do
        before :each do
          sign_in @staff
        end

        it "should not show Move Up if there is no time to move it forward to" do
          allow_any_instance_of(Reservation).to receive(:earliest_possible).and_return(nil)
          do_request
          expect(response.body).not_to include("Move Up")
        end

        it "should show Move Up if there is a time to move it forward to" do
          allow_any_instance_of(Reservation).to receive(:earliest_possible).and_return(Reservation.new)
          do_request
          expect(response.body).to include("Move Up")
        end
      end
    end

    context "all" do
      before :each do
        @params = { status: "all" }
      end

      it "should respond with all order details that have a reservation" do
        maybe_grant_always_sign_in :staff
        do_request
        expect(assigns(:status)).to eq("all")
        expect(assigns(:available_statuses).size).to eq(2)
        expect(assigns(:order_details)).to eq(OrderDetail.with_reservation)
        expect(assigns(:active_tab)).to eq("reservations")
        is_expected.to render_template("list")
      end
    end
  end

  context "creating a reservation in the past" do
    before :each do
      @method = :post
      @action = :create
      @order = @guest.orders.create(FactoryBot.attributes_for(:order, created_by: @admin.id, account: @account))
      @order.add(@instrument, 1)
      @order_detail = @order.order_details.first
      @price_policy_past = create(:instrument_price_policy, product: @instrument, price_group_id: @price_group.id, start_date: 7.days.ago, expire_date: 1.day.ago, usage_rate: 120, charge_for: InstrumentPricePolicy::CHARGE_FOR[:usage])
      @params = {
        order_id: @order.id,
        order_detail_id: @order_detail.id,
        order_account: @account.id,
        reservation: {
          reserve_start_date: format_usa_date(Time.zone.now.to_date - 5.days),
          reserve_start_hour: "9",
          reserve_start_min: "0",
          reserve_start_meridian: "am",
          duration_mins: "60",
        },
      }
    end

    it_should_allow_all facility_operators, "should redirect" do
      assert_redirected_to purchase_order_path(@order)
    end

    it_should_allow_all facility_operators, "and not have errors" do
      expect(assigns[:reservation].errors).to be_empty
    end

    it_should_allow_all facility_operators, "and not assign actuals" do
      expect(assigns[:reservation].actual_start_at).to be_nil
      expect(assigns[:reservation].actual_end_at).to be_nil
    end

    it_should_allow_all facility_operators, "to still be new" do
      expect(assigns[:reservation].order_detail.reload.state).to eq("new")
    end

    it_should_allow_all facility_operators, "and isn't a problem" do
      expect(assigns[:reservation].order_detail.reload).not_to be_problem_order
    end

    it_should_allow_all [:guest], "to receive an error they are trying to reserve in the past" do
      expect(assigns[:reservation].errors).not_to be_empty
      expect(response).to render_template(:new)
    end

    it_should_allow_all facility_operators, "not set a price policy" do
      expect(assigns[:reservation].order_detail.reload.price_policy).to be_nil
    end

    it_should_allow_all facility_operators, "set the right estimated price" do
      expect(assigns[:reservation].order_detail.reload.estimated_cost).to eq(120)
    end
  end

  describe "POST #create" do
    before :each do
      @method = :post
      @action = :create
      @params.merge!(
        order_account: @account.id,
        reservation: {
          reserve_start_date: format_usa_date(Time.zone.now.to_date + 1.day),
          reserve_start_hour: "9",
          reserve_start_min: "0",
          reserve_start_meridian: "am",
          duration_mins: "60",
        },
      )
    end

    it_should_allow_all facility_users, "to create reservation for tomorrow @ 8 am for 60 minutes, set order detail price estimates" do
      expect(assigns[:order]).to eq(@order)
      expect(assigns[:order_detail]).to eq(@order_detail)
      expect(assigns[:instrument]).to eq(@instrument)
      expect(assigns[:reservation]).to be_valid
      expect(assigns[:order_detail].estimated_cost).not_to be_nil
      expect(assigns[:order_detail].estimated_subsidy).not_to be_nil
      is_expected.to set_flash
      assert_redirected_to purchase_order_path(@order)
    end

    it_behaves_like "it can handle having its order_detail removed"

    context "notifications when acting as" do
      before :each do
        sign_in @admin
        switch_to @guest
      end

      it "should set the option for sending notifications" do
        @params[:send_notification] = "1"
        do_request
        expect(response).to redirect_to purchase_order_path(@order, send_notification: "1")
      end

      it "should set the option for not sending notifications" do
        @params[:send_notification] = "0"
        do_request
        expect(response).to redirect_to purchase_order_path(@order)
      end
    end

    context "merge order" do
      before :each do
        @merge_to_order = @order.dup
        assert @merge_to_order.save
        assert @order.update_attribute :merge_with_order_id, @merge_to_order.id
      end

      it_should_allow :director, "to create a reservation on merge order detail and redirect to order summary when merge order is destroyed" do
        assert_redirected_to facility_order_path(@authable, @merge_to_order)
        expect { Order.find(order.id) }.to raise_error ActiveRecord::RecordNotFound
      end

      context "extra order details" do
        before :each do
          @service = @authable.services.create(FactoryBot.attributes_for(:service, facility_account_id: @facility_account.id))
          allow_any_instance_of(Service).to receive(:active_survey?).and_return(true)
          @service_order_detail = @order.order_details.create(FactoryBot.attributes_for(:order_detail, product_id: @service.id, account_id: @account.id))
        end

        it_should_allow :director, "to create a reservation on merge order detail and redirect to order summary when merge order is not destroyed" do
          assert_redirected_to facility_order_path(@authable, @merge_to_order)
          expect { Order.find(order.id) }.not_to raise_error
        end
      end

      context "creating a reservation in the past" do
        before :each do
          @params.deep_merge!(reservation: { reserve_start_date: 1.day.ago })
        end

        it_should_allow_all facility_operators, "to create a reservation in the past and have it be complete" do
          expect(assigns(:reservation).errors).to be_empty
          expect(assigns(:order_detail).state).to eq("complete")
          expect(response).to redirect_to facility_order_path(@authable, @merge_to_order)
        end

        it_should_allow_all facility_operators, "and not assign actuals" do
          expect(assigns[:reservation].actual_start_at).to be_nil
          expect(assigns[:reservation].actual_end_at).to be_nil
        end

        context "and there is no price policy" do
          before :each do
            @price_policy.update_attributes(expire_date: 2.days.ago)
          end

          it_should_allow_all facility_operators, "to create the reservation, but have it be a problem order" do
            expect(assigns(:order_detail).state).to eq("complete")
            expect(assigns(:order_detail)).to be_problem_order
          end
        end
      end

      context "creating a reservation in the future" do
        before :each do
          @params.deep_merge!(reservation: { reserve_start_date: 1.day.from_now })
        end

        it_should_allow_all facility_operators, "to create a reservation in the future" do
          expect(assigns(:reservation).errors).to be_empty
          expect(assigns(:order_detail).state).to eq("new")
          expect(response).to redirect_to facility_order_path(@authable, @merge_to_order)
        end
      end
    end

    context "creating a reservation in the future" do
      before :each do
        @params.deep_merge!(reservation: { reserve_start_date: Time.zone.now.to_date + (PriceGroupProduct::DEFAULT_RESERVATION_WINDOW + 1).days })
      end

      it_should_allow_all facility_operators, "to create a reservation beyond the default reservation window" do
        assert_redirected_to purchase_order_path(@order)
      end

      it_should_allow_all [:guest], "to receive an error that they are trying to reserve outside of the window" do
        expect(assigns[:reservation].errors).not_to be_empty
        expect(flash[:error]).to include("The reservation is too far in advance")
        expect(response).to render_template(:new)
      end
    end

    context "creating a reservation in the future with no price policy" do
      before :each do
        @params[:reservation][:reserve_start_date] = format_usa_date(@price_policy.expire_date + 1.day)
        @price_group_product.update_attributes(reservation_window: 365)
        sign_in @guest
        do_request
      end
      it "should allow creation" do
        expect(assigns[:reservation]).not_to be_nil
        expect(assigns[:reservation]).not_to be_new_record
      end
    end

    context "without account" do
      before :each do
        @params.delete :order_account
        sign_in @guest
        do_request
      end
      it "should have a flash message and render :new" do
        expect(flash[:error]).to be_present
        expect(response).to render_template :new
      end
      it "should maintain duration value" do
        expect(assigns[:reservation].duration_mins).to eq(60)
      end
      it "should not lose the time" do
        expect(assigns[:reservation].reserve_start_date).to eq(format_usa_date(Time.zone.now.to_date + 1.day))
        expect(assigns[:reservation].reserve_start_hour).to eq(9)
        expect(assigns[:reservation].reserve_start_min).to eq(0)
        expect(assigns[:reservation].reserve_start_meridian).to eq("am")
      end
      it "should assign the correct variables" do
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order_detail]).to eq(@order_detail)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(flash[:error]).to be_present
        is_expected.to render_template :new
      end
    end

    context "with new account" do

      before :each do
        @account2 = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @guest))
        define_open_account(@instrument.account, @account2.account_number)
        @params[:order_account] = @account2.id
        expect(@order.account).to eq(@account)
        expect(@order_detail.account).to eq(@account)
      end

      it_should_allow :guest do
        expect(@order.reload.account).to eq(@account2)
        expect(@order.order_details.first.account).to eq(@account2)
        expect(@order_detail.reload.account).to eq(@account2)
      end
    end

    context "with a price policy attached to the account" do
      before :each do
        @order.update_attributes(account: nil)
        expect(@order.account).to be_nil
        expect(@order_detail.account).to be_nil
        @instrument.price_policies.first.update_attributes usage_rate: 240
        @price_group2 = FactoryBot.create(:price_group, facility: facility)
        @pg_account        = FactoryBot.create(:account_price_group_member, account: @account, price_group: @price_group2)
        @price_policy2     = create :instrument_price_policy, product: @instrument, price_group_id: @price_group2.id, usage_rate: 120, usage_subsidy: 15
        sign_in @guest
      end
      it "should use the policy based on the account because it's cheaper" do
        do_request
        expect(assigns[:order_detail].estimated_cost).to eq(120.0)
        expect(assigns[:order_detail].estimated_subsidy).to eq(15)
      end
    end

    it "handles arbitrary errors" do
      sign_in @guest
      @params[:order_account] = 0 # Cause Account not found error
      expect { do_request }.not_to change(Reservation, :count)
      expect(response.body).to include(I18n.t("orders.purchase.error", message: ""))
    end

    context "with other things in the cart (bundle or multi-add)" do

      before :each do
        @order.add(@instrument, 1)
      end

      it_should_allow :staff, "but should redirect to cart" do
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order_detail]).to eq(@order_detail)
        expect(assigns[:instrument]).to eq(@instrument)
        expect(assigns[:reservation]).to be_valid
        expect(assigns[:order_detail].estimated_cost).not_to be_nil
        expect(assigns[:order_detail].estimated_subsidy).not_to be_nil
        is_expected.to set_flash
        assert_redirected_to cart_path
      end
    end
  end

  describe "GET #new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_all facility_users do
      expect(assigns[:order]).to eq(@order)
      expect(assigns[:order_detail]).to eq(@order_detail)
      expect(assigns[:instrument]).to eq(@instrument)
      expect(assigns(:reservation)).to be_kind_of Reservation
      expect(assigns(:max_window)).to be_kind_of Integer

      expect(assigns[:max_date]).to eq((Time.zone.now + assigns[:max_window].days).strftime("%Y%m%d"))
    end

    # Managers should be able to go far out into the future
    it_should_allow_all facility_operators do
      expect(assigns[:max_window]).to eq(365)
      expect(assigns[:max_days_ago]).to eq(-365)
      expect(assigns[:min_date]).to eq((Time.zone.now + assigns[:max_days_ago].days).strftime("%Y%m%d"))
      expect(assigns[:max_date]).to eq((Time.zone.now + 365.days).strftime("%Y%m%d"))
    end

    # guests should only be able to go the default reservation window into the future
    it_should_allow_all [:guest] do
      expect(assigns[:max_window]).to eq(PriceGroupProduct::DEFAULT_RESERVATION_WINDOW)
      expect(assigns[:max_days_ago]).to eq(0)
      expect(assigns[:max_date]).to eq((Time.zone.now + PriceGroupProduct::DEFAULT_RESERVATION_WINDOW.days).strftime("%Y%m%d"))
      expect(assigns[:min_date]).to eq(Time.zone.now.strftime("%Y%m%d"))
    end

    it_behaves_like "it can handle having its order_detail removed"

    describe "default reservation time" do
      before :each do
        sign_in @guest
        allow(controller).to receive :set_windows
      end
      context "the instrument has a minimum reservation time" do
        before :each do
          @instrument.update_attributes(min_reserve_mins: 35)
          do_request
        end

        it "should set the time to the minimum reservation time" do
          expect(assigns(:reservation).duration_mins).to eq(35)
        end
      end

      context "the instrument has zero minimum reservation minutes" do
        before :each do
          @instrument.update_attributes(min_reserve_mins: 0)
          do_request
        end

        it "should default to 30 minutes" do
          expect(assigns(:reservation).duration_mins).to eq(30)
        end
      end

      context "the instrument has nil minimum reservation minutes" do
        before :each do
          @instrument.update_attributes(min_reserve_mins: nil)
          do_request
        end

        it "should default to 30 minutes" do
          expect(assigns(:reservation).duration_mins).to eq(30)
        end
      end
    end

    context "rounding times" do
      before :each do
        sign_in @guest
        allow(controller).to receive :set_windows
        allow_any_instance_of(Instrument).to receive(:next_available_reservation).and_return(next_reservation)
        do_request
      end

      context "next reservation is between 5 minutes" do
        let(:reserve_interval) { 1 }

        let(:next_reservation) do
          Reservation.new reserve_start_at: Time.zone.parse("2013-08-15 12:02"),
                          reserve_end_at: Time.zone.parse("2013-08-15 12:17"),
                          product: create(:setup_instrument, reserve_interval: reserve_interval)
        end

        it "should default the duration mins to minimum duration" do
          expect(assigns(:reservation).duration_mins).to eq(15)
        end

        describe "and the instrument has a one minute interval" do
          let(:reserve_interval) { 1 }

          it "should not do any additional rounding" do
            expect(assigns(:reservation).reserve_start_min).to eq(2)
          end
        end

        describe "and the instrument has a 5 minute interval" do
          let(:reserve_interval) { 5 }

          it "should round up to the nearest 5 minutes" do
            expect(assigns(:reservation).reserve_start_min).to eq(5)
          end
        end

        describe "and the instrument has a 15 minute interval" do
          let(:reserve_interval) { 15 }
          it "should round up to the nearest 15 minutes" do
            expect(assigns(:reservation).reserve_start_min).to eq(15)
          end
        end
      end

      context "next reservation is on a 5 minute, but with seconds" do
        let(:next_reservation) do
          Reservation.new reserve_start_at: Time.zone.parse("2013-08-15 12:05:30"),
                          reserve_end_at: Time.zone.parse("2013-08-15 12:20:30"),
                          product: create(:setup_instrument)
        end

        it "should round up to the nearest 5 minutes" do
          expect(assigns(:reservation).reserve_start_min).to eq(5)
        end

        it "should default the duration mins to minimum duration" do
          expect(assigns(:reservation).duration_mins).to eq(15)
        end
      end
    end

    context "a user with no price groups" do
      before :each do
        sign_in @guest
        allow_any_instance_of(User).to receive(:price_groups).and_return([])
        @order_detail.update_attributes(account: nil)
        # Only worry about one price group product
        @instrument.price_group_products.destroy_all
        pgp = FactoryBot.create(:price_group_product, product: @instrument, price_group: FactoryBot.create(:price_group, facility: @authable), reservation_window: 14)
      end

      it "does not have an account on the order detail" do
        do_request
        expect(assigns(:order_detail).account).to be_nil
      end

      it "is a successful page render" do
        do_request
        expect(response).to be_successful
      end

      it "uses the minimum reservation window" do
        pgp2 = FactoryBot.create(:price_group_product, product: @instrument, price_group: FactoryBot.create(:price_group, facility: @authable), reservation_window: 7)
        pgp3 = FactoryBot.create(:price_group_product, product: @instrument, price_group: FactoryBot.create(:price_group, facility: @authable), reservation_window: 21)
        do_request
        expect(assigns(:max_window)).to eq(7)
      end
    end

    describe "restricted instrument" do
      let(:not_authorized_message) { "not on the authorized list" }

      before :each do
        @instrument.update_attributes(requires_approval: true)
      end

      context "acting as non-authorized user" do
        before :each do
          sign_in @admin
          switch_to @guest
        end

        it "shows correctly" do
          do_request
          expect(response).to be_successful
          expect(response.body).to include(not_authorized_message)
        end
      end

      context "acting a authorized user" do
        before :each do
          sign_in @admin
          ProductUser.create!(product: @instrument, user: @guest, approved_by: @admin.id)
          switch_to @guest
        end

        it "shows correctly" do
          do_request
          expect(response).to be_successful
          expect(response.body).not_to include(not_authorized_message)
        end
      end

      describe "as a merge order" do
        describe "ordering for an authorized user" do
          before do
            @merge_to_order = @order.dup
            assert @merge_to_order.save
            assert @order.update_attribute :merge_with_order_id, @merge_to_order.id
            @instrument.update_attributes(requires_approval: true)
            ProductUser.create!(product: @instrument, user: @guest, approved_by: @admin.id)
            sign_in @admin
          end

          it "does not see the authorized user note" do
            do_request
            expect(response.body).not_to include(not_authorized_message)
          end
        end
      end
    end
  end

  context "needs future reservation" do
    before :each do
      # create reservation for tomorrow @ 9 am for 60 minutes, with order detail reference
      @start        = Time.zone.now.end_of_day + 1.second + 9.hours
      @reservation  = @instrument.reservations.create(reserve_start_at: @start, order_detail: @order_detail,
                                                      duration_mins: 60, split_times: true)
      assert @reservation.valid?
    end

    context "show" do
      before :each do
        @method = :get
        @action = :show
        @params.merge!(id: @reservation.id)
      end

      it_should_allow_all facility_users do
        expect(assigns[:reservation]).to eq(@reservation)
        expect(assigns[:order_detail]).to eq(@reservation.order_detail)
        expect(assigns[:order]).to eq(@reservation.order_detail.order)
        is_expected.to respond_with :success
      end
    end

    # Many happy paths are tested in features purchasing_a_reservation,
    # editing_a_reservation, and purchasing_a_reservation_on_behalf_of
    describe "#update" do
      before(:each) do
        @method = :put
        @action = :update
        @params.merge!(
          id: reservation.id,
          reservation: {
            reserve_start_date: @start.to_date,
            reserve_start_hour: "10",
            reserve_start_min: "0",
            reserve_start_meridian: "am",
            duration_mins: "60",
          },
        )
      end

      describe "updating the note" do
        before(:each) do
          sign_in reservation.user
          @params[:reservation][:note] = "This is an updated note"
          do_request
        end

        it "updates the note" do
          expect(reservation.reload.note).to eq("This is an updated note")
        end
      end

      describe "updating to blank on a required note instrument" do
        before(:each) do
          instrument.update!(user_notes_field_mode: "required")
          sign_in reservation.user
          @params[:reservation][:note] = ""
          do_request
        end

        it "renders with an error" do
          expect(response).to render_template(:edit)
          expect(response.body).to include("may not be blank")
        end
      end

      describe "when trying to update a past reservation" do
        before(:each) do
          sign_in @admin
          expect(controller).to receive(:invalid_for_update?).and_return true
          do_request
        end

        it "redirects to the show page" do
          expect(response).to redirect_to([order, order_detail, reservation])
          expect(flash[:notice]).to be_present
        end
      end

      describe "when trying to update a running reservation" do
        context "as staff" do
          before(:each) do
            maybe_grant_always_sign_in(:staff)
            reservation.update_attribute(:actual_start_at, @start.to_date)
          end

          it "runs validations" do
            expect_any_instance_of(Reservations::DurationChangeValidations)
              .to receive(:valid?)
              .and_return(false)
            do_request
          end

          it "ignores start fields" do
            expect_any_instance_of(Reservations::DurationChangeValidations)
              .to receive(:valid?)
              .and_return(false)
            do_request
            expect(reservation.reload.reserve_start_date)
              .to eq(@start.strftime("%m/%d/%Y"))
            expect(reservation.reload.reserve_start_hour).to eq(9)
            expect(reservation.reload.reserve_start_min).to eq(0)
            expect(reservation.reload.reserve_start_meridian).to eq("AM")
          end

          context "with errors" do
            it "renders edit" do
              expect_any_instance_of(Reservations::DurationChangeValidations)
                .to receive(:valid?)
                .and_return(true)
              do_request
              expect(response).to render_template(:edit)
            end
          end
        end
      end

      context "when creating a reservation in the future" do
        let(:reserve_start_date) do
          (PriceGroupProduct::DEFAULT_RESERVATION_WINDOW + 1).days.from_now
        end

        before(:each) do
          @params.deep_merge!(
            reservation: { reserve_start_date: reserve_start_date },
          )
        end

        it_should_allow_all facility_operators, "to create a reservation beyond the default reservation window" do
          expect(assigns[:reservation].errors).to be_empty
          assert_redirected_to cart_url
        end

        it_should_allow_all [:guest], "to receive an error that they are trying to reserve outside of the window" do
          expect(assigns[:reservation].errors).to be_present
          expect(response).to render_template(:edit)
        end
      end
    end
  end

  context "earliest move possible" do
    before :each do
      @method = :get
      @action = :earliest_move_possible

      maybe_grant_always_sign_in :guest
    end

    context "valid short reservation" do
      before :each do
        @reservation = @instrument.reservations.create(
          reserve_start_at: Time.zone.now + 1.day,
          order_detail: @order_detail,
          duration_mins: 60,
          split_times: true,
        )

        @params[:reservation_id] = @reservation.id
        do_request
      end

      it "should get earliest move possible" do
        expect(response.code).to eq("200")
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response).to render_template "reservations/earliest_move_possible"
        expect(response.body.to_s).to match(/The earliest time you can move this reservation to begins on [^<>]+ at [^<>]+ and ends at [^<>]+./)
      end
    end

    context "valid long reservation" do
      before :each do
        # remove all scheduling rules/constraints to allow for the creation of a long reservation
        @instrument.schedule_rules.destroy_all
        @instrument.update_attributes max_reserve_mins: nil
        FactoryBot.create(:all_day_schedule_rule, product: @instrument)

        @reservation = @instrument.reservations.create!(
          reserve_start_at: Time.zone.now + 1.day,
          order_detail: @order_detail,
          duration_mins: 24 * 60,
          split_times: true,
        )

        @params[:reservation_id] = @reservation.id
        do_request
      end

      it "should get earliest move possible" do
        expect(response.code).to eq("200")
        expect(response.headers["Content-Type"]).to eq("text/html; charset=utf-8")
        expect(response).to render_template "reservations/earliest_move_possible"
        expect(response.body.to_s).to match(/The earliest time you can move this reservation to begins on [^<>]+ at [^<>]+ and ends on [^<>]+ at [^<>]+./)
      end
    end

    context "invalid reservation" do
      before :each do
        @params[:reservation_id] = 999
        do_request
      end

      it "should return a 404" do
        expect(response.code).to eq("404")
      end
    end
  end

  describe "#move" do
    let(:reservation) do
      create(:reservation, :tomorrow, product: instrument, order_detail: order_detail)
    end

    before(:each) do
      @method = :post
      @action = :move
      expect(reservation.reserve_start_at)
        .not_to eq(reservation.earliest_possible.reserve_start_at)
      expect(reservation.reserve_end_at)
        .not_to eq(reservation.earliest_possible.reserve_end_at)
      @params.merge!(reservation_id: reservation.id)
    end

    it_should_allow :guest, "to move a reservation" do
      expect(assigns(:order)).to eq(order)
      expect(assigns(:order_detail)).to eq(order_detail)
      expect(assigns(:instrument)).to eq(instrument)
      expect(assigns(:reservation)).to eq(reservation)
      expect(format_usa_datetime(assigns(:reservation).reserve_start_at))
        .to eq(format_usa_datetime(reservation.earliest_possible.reserve_start_at))
      expect(format_usa_datetime(assigns(:reservation).reserve_end_at))
        .to eq(format_usa_datetime(reservation.earliest_possible.reserve_end_at))
      is_expected.to set_flash
      assert_redirected_to reservations_status_path(status: "upcoming")
    end
  end

  context "needs now reservation" do
    before :each do
      # create reservation for tomorrow @ 9 am for 60 minutes, with order detail reference
      @start        = Time.zone.now + 1.second
      @reservation  = @instrument.reservations.create(reserve_start_at: @start, order_detail: @order_detail,
                                                      duration_mins: 60, split_times: true)
      assert @reservation.valid?
    end

    context "move" do
      before :each do
        @method = :post
        @action = :move
        expect(@reservation.earliest_possible).to be_nil
        @orig_start_at = @reservation.reserve_start_at
        @orig_end_at = @reservation.reserve_end_at
        @params.merge!(reservation_id: @reservation.id)
      end

      it_should_allow :guest, "but not move the reservation" do
        expect(assigns(:order)).to eq(@order)
        expect(assigns(:order_detail)).to eq(@order_detail)
        expect(assigns(:instrument)).to eq(@instrument)
        expect(assigns(:reservation)).to eq(@reservation)
        expect(format_usa_datetime(assigns(:reservation).reserve_start_at)).to eq(format_usa_datetime(@orig_start_at))
        expect(format_usa_datetime(assigns(:reservation).reserve_end_at)).to eq(format_usa_datetime(@orig_end_at))
        is_expected.to set_flash
        assert_redirected_to reservations_status_path(status: "upcoming")
      end
    end

    context "switch_instrument", :time_travel do
      before :each do
        @method = :get
        @action = :switch_instrument
        @params[:reservation_id] = @reservation.id
        create(:relay, instrument: @instrument)
        @random_user = create(:user)
        @instrument.update!(min_reserve_mins: 30)
        @instrument.schedule_rules.update_all(start_hour: 0)
      end

      context "on" do
        before :each do
          @params.merge!(switch: "on")
        end

        context "as the user" do
          before :each do
            sign_in @guest
            do_request
          end

          it "assigns the proper variables" do
            expect(assigns(:order)).to eq(@order)
            expect(assigns(:order_detail)).to eq(@order_detail)
            expect(assigns(:instrument)).to eq(@instrument)
            expect(assigns(:reservation)).to eq(@reservation)
          end

          it "updates the instrument status" do
            expect(assigns(:instrument).instrument_statuses.size).to eq(1)
            expect(assigns(:instrument).instrument_statuses[0].is_on).to eq(true)
          end

          it "responds properly" do
            is_expected.to set_flash
            is_expected.to respond_with :redirect
          end

          it "starts the reservation" do
            expect(assigns(:reservation).actual_start_at).to eq(Time.zone.now)
          end
        end

        it_should_allow_all facility_operators, "turn on instrument from someone elses reservation" do
          is_expected.to respond_with :redirect
        end

        it_should_deny :random_user

        context "before the reservation start (in grace period)" do
          let(:start_at) { 3.minutes.from_now }
          let(:end_at) { 63.minutes.from_now }

          before :each do
            @reservation.update_attributes!(reserve_start_at: start_at, reserve_end_at: end_at)
            sign_in @guest
          end

          context "for a restricted instrument" do
            before { @instrument.update_attributes(requires_approval: true) }
            it "allows it to start" do
              do_request
              expect(assigns(:reservation).actual_start_at).to eq(Time.zone.now)
            end
          end

          context "and the reservation is already at maximum length" do
            before do
              @instrument.update_attributes(max_reserve_mins: 60)
              do_request
            end

            it "allows it to start" do
              expect(assigns(:reservation).actual_start_at).to eq(Time.zone.now)
            end
          end

          context "in the grace period, but there is another reservation still running" do
            let!(:reservation2) do
              create(:purchased_reservation, product: @instrument,
                                             reserve_start_at: start_at - 30.minutes,
                                             reserve_end_at: start_at,
                                             actual_start_at: start_at - 30.minutes)
            end

            it "does not start the reservation" do
              do_request
              expect(assigns(:reservation)).not_to be_started
              expect(flash[:error]).to match(/previously scheduled reservation is ongoing/)
            end
          end

          context "and there is a non-started reservation" do
            let!(:reservation2) do
              create(:purchased_reservation, product: @instrument,
                                             reserve_start_at: start_at - 30.minutes,
                                             reserve_end_at: start_at,
                                             actual_start_at: nil)
            end

            it "allows it to start" do
              do_request
              expect(assigns(:reservation).actual_start_at).to eq(Time.zone.now)
            end
          end
        end

        context "when there is a prior reservation overrunning its time" do
          let(:start_at) { 3.minutes.ago.change(usec: 0) }
          let(:end_at) { 57.minutes.from_now.change(usec: 0) }

          let!(:reservation2) do
            create(:purchased_reservation, product: @instrument,
                                           reserve_start_at: start_at - 60.minutes,
                                           reserve_end_at: start_at,
                                           actual_start_at: start_at - 60.minutes)
          end

          before :each do

            @reservation.update_attributes!(reserve_start_at: start_at, reserve_end_at: end_at)
            sign_in @guest
          end

          it "starts the reservation" do
            do_request
            expect(assigns(:reservation)).to be_started
          end

          it "moves the other reservation to the problem queue" do
            do_request
            expect(reservation2.order_detail.reload).to be_problem
          end
        end

        context "after the reservation starts" do
          let(:start_at) { 3.minutes.ago.change(usec: 0) }
          let(:end_at) { 57.minutes.from_now.change(usec: 0) }

          before :each do
            @reservation.update_attributes!(reserve_start_at: start_at, reserve_end_at: end_at)
            sign_in @guest
            do_request
          end

          it "does not change the reservation start time" do
            expect(assigns(:reservation).reserve_start_at).to eq(start_at)
            expect(assigns(:reservation).reserve_end_at).to eq(end_at)
          end
        end

      end

      context "off" do
        before :each do
          @reservation.update_attribute(:actual_start_at, @start)
          @params[:switch] = "off"
          travel(2.seconds)
          expect(@reservation.order_detail.price_policy).to be_nil
        end

        it_should_allow :guest do
          expect(assigns(:order)).to eq(@order)
          expect(assigns(:order_detail)).to eq(@order_detail)
          expect(assigns(:instrument)).to eq(@instrument)
          expect(assigns(:reservation)).to eq(@reservation)
          expect(assigns(:reservation).order_detail.price_policy).not_to be_nil
          expect(assigns(:reservation).actual_end_at).to be <= Time.zone.now
          expect(assigns(:reservation)).to be_complete
          expect(assigns(:instrument).instrument_statuses.size).to eq(1)
          expect(assigns(:instrument).instrument_statuses[0].is_on).to eq(false)
          is_expected.to set_flash
          is_expected.to respond_with :redirect
        end

        it_should_allow_all facility_operators, "turn off instrument from someone elses reservation" do
          is_expected.to respond_with :redirect
        end
        it_should_deny :random_user

        context "for instrument w/ accessory" do
          before :each do
            ## (setup stolen from orders_controller_spec)
            ## create a purchasable item
            @item = @authable.items.create(FactoryBot.attributes_for(:item, facility_account_id: @facility_account.id))
            @item_pp = @item.item_price_policies.create(FactoryBot.attributes_for(:item_price_policy, price_group_id: @price_group.id))
            @item_pp.reload.restrict_purchase = false

            ## make it an accessory of the reserved product
            @instrument.product_accessories.create!(accessory: @item)
          end

          it_should_allow :guest, "it redirects to the accessories" do
            is_expected.to redirect_to new_order_order_detail_accessory_path(@order, @order_detail)
          end
        end

        context "and a reservation using the same relay as another running reservation" do
          let!(:reservation_running) do
            create(:purchased_reservation, product: @instrument,
                                           actual_start_at: 30.minutes.ago, reserve_start_at: 30.minutes.ago,
                                           reserve_end_at: 30.minutes.from_now)
          end

          before { @params[:reservation_id] = reservation_running.id }

          it "does not switch off the relay" do
            expect_any_instance_of(ReservationInstrumentSwitcher).to_not receive(:switch_off!)

            sign_in @guest
            do_request
          end
        end
      end
    end
  end

  describe "timeline as guest", feature_setting: { daily_view: true, reload_routes: true } do
    let!(:hidden_instrument) do
      create(
        :instrument,
        facility_account: @facility_account,
        facility: @authable,
        is_hidden: true,
      )
    end

    before :each do
      maybe_grant_always_sign_in :guest
      @method = :get
      @action = :public_timeline
      @params = { facility_id: @authable.url_name }
      do_request
      expect(response).to render_template :public_timeline
    end

    it "considers display for every active schedule" do
      expect(assigns(:schedules)).to match_array [@instrument.schedule, hidden_instrument.schedule]
    end

    it "displays visible instruments only" do
      expect(response.body).to include @instrument.name
      expect(response.body).to_not include hidden_instrument.name
    end

    it "does not allow controlling of relays" do
      expect(response.body).to_not include "relay[#{@instrument.id}]"
    end

    it "does not allow showing of canceled reservations" do
      expect(response.body).to_not include "show_canceled"
    end
  end

  describe "get #show" do
    let(:start) { Time.zone.now.end_of_day + 1.second + 9.hours }
    let(:reservation) do
      @instrument.reservations.create!(
        reserve_start_at: start, order_detail: @order_detail,
        duration_mins: 60, split_times: true)
    end

    before(:example) do
      sign_in(@admin)
    end

    context "normal HTML" do
      it "renders the normal template" do
        Rails.logger.ap reservation.errors
        get :show, params: { order_id: @order.id, order_detail_id: @order_detail.id,
                             id: reservation.id }
        is_expected.to render_template("show")
      end
    end

    context "ical" do
      it "downloads an ical" do
        get :show, params: { order_id: @order.id, order_detail_id: @order_detail.id,
                             id: reservation.id, format: :ics }
        expect(response.body).to match(/BEGIN:VCALENDAR/)
      end

    end

  end

end
