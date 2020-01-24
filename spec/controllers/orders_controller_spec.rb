# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe OrdersController do
  include DateHelper

  render_views

  before(:all) { create_users }

  class DummyNotifier

    def deliver_later
    end

  end

  it "routes properly" do
    expect(get: "/orders/cart").to route_to(controller: "orders", action: "cart")
    expect(get: "/orders/1").to route_to(controller: "orders", action: "show", id: "1")
    expect(put: "/orders/1").to route_to(controller: "orders", action: "update", id: "1")
    expect(put: "/orders/1/add").to route_to(controller: "orders", action: "add", id: "1")
    expect(put: "/orders/1/remove/3").to route_to(controller: "orders", action: "remove", id: "1", order_detail_id: "3")
    expect(put: "/orders/1").to route_to(controller: "orders", action: "update", id: "1")
    expect(put: "/orders/1/clear").to route_to(controller: "orders", action: "clear", id: "1")
    expect(put: "/orders/1/purchase").to route_to(controller: "orders", action: "purchase", id: "1")
    expect(get: "/orders/1/receipt").to route_to(controller: "orders", action: "receipt", id: "1")
    expect(get: "/orders/1/choose_account").to route_to(controller: "orders", action: "choose_account", id: "1")
  end

  let(:account) { @account }
  let(:facility) { create(:setup_facility) }
  let(:item) { @item }
  let(:params) { @params }
  let(:price_group) { @price_group }
  let(:order) { @order }

  before(:each) do
    @authable = facility
    @price_group = FactoryBot.create(:price_group, facility: facility)
    @item = FactoryBot.create(:item, facility: facility)
    @account = add_account_for_user(:staff, @item, @price_group)
    @order = @staff.orders.create(FactoryBot.attributes_for(:order, created_by: @staff.id, account: @account))

    @item_pp = @item.item_price_policies.create!(FactoryBot.attributes_for(:item_price_policy, price_group_id: @price_group.id, start_date: 1.hour.ago))

    @params = { id: @order.id, order_id: @order.id }
  end

  context "cart" do
    before :each do
      @method = :get
      @action = :cart
    end

    it_should_require_login

    it_should_allow :staff do
      assert_redirected_to order_url(@order)
    end

    context "signed in" do
      before(:each) { sign_in @staff }

      context "with an item" do
        before :each do
          @order.add(@item, 1)
        end

        it "redirects to the order" do
          do_request
          expect(request).to redirect_to order_url(@order)
        end
      end

      context "cart with one reservation" do
        before :each do
          @instrument = FactoryBot.create(:setup_instrument, facility: @authable)
          @order.add(@instrument, 1)
          @res1 = FactoryBot.create(:setup_reservation, order_detail: @order.order_details[0], product: @instrument)
        end

        it "redirects to a new cart" do
          do_request
          expect(request).not_to redirect_to order_url(@order)
        end

        context "with a second reservation" do
          before :each do
            @instrument2 = FactoryBot.create(:setup_instrument, facility: @authable)
            @order.add(@instrument2, 1)
            @res2 = FactoryBot.create(:setup_reservation, order_detail: @order.order_details[2], product: @instrument)
          end

          it "redirects to the existing cart" do
            do_request
            expect(request).to redirect_to order_url(@order)
          end
        end
      end
    end
  end

  describe "GET #choose_account" do
    before(:each) do
      expect { order.add(item, 1) }
        .to change(order.order_details, :size).from(0).to(1)

      @method = :get
      @action = :choose_account
      @params.merge!(account_id: account.id)
    end

    it_should_require_login

    it_should_allow :staff do
      expect(assigns(:order)).to be_kind_of(Order).and eq(order)
      is_expected.to render_template "choose_account"
    end

    context "with a logged-in staff user" do
      before { sign_in @staff }

      context "and an empty cart" do
        before(:each) do
          new_order = @staff.orders.create(attributes_for(:order, created_by: @staff.id, account: account))
          expect(new_order.order_details).to be_empty

          @params = { id: new_order.id }
          do_request
        end

        it { expect(response).to redirect_to(cart_path) }
      end

      context "when add_to_cart is set in the session" do
        before(:each) do
          session[:add_to_cart] = [{ product_id: added_item_id }]
          do_request
        end

        context "and the product exists" do
          let(:added_item) { create(:setup_item) }
          let(:added_item_id) { added_item.id }

          it "sets @product to the first product in the cart" do
            expect(assigns(:product)).to eq(added_item)
          end
        end

        context "and the product does not exist" do
          let(:added_item_id) { 0 }

          it { expect(response.response_code).to eq(404) }
        end
      end

      context "when add_to_cart is not set in the session" do
        context "and there are no order_details" do
          before(:each) do
            order.order_details.destroy_all
            do_request
          end

          it { expect(response).to redirect_to(cart_path) }
        end

        context "and there are order_details" do
          before { do_request }

          it "sets @product to the first product in the first order_detail" do
            expect(assigns(:product)).to eq(order.order_details.first.product)
          end
        end
      end
    end
  end

  describe "POST #choose_account" do
    let(:order_detail) { order.order_details.first }
    let(:other_account) { add_account_for_user(:staff, item, price_group) }

    before(:each) do
      sign_in @staff

      expect { order.add(item, 1) }
        .to change(order.order_details, :size).from(0).to(1)

      @method = :post
      @action = :choose_account
    end

    shared_examples_for "it uses add_to_cart to determine redirects" do
      context "when add_to_cart is set in the session" do
        before(:each) do
          session[:add_to_cart] = [{ product_id: item.id }]
          do_request
        end

        it { expect(response).to redirect_to(add_order_path(order)) }
      end

      context "when add_to_cart is not set in the session" do
        before { do_request }

        it { expect(response).to redirect_to(cart_path) }
      end
    end

    context "when selecting a different account" do
      before { @params.merge!(account_id: other_account.id) }

      context "that the user is allowed to use" do
        it "updates the account associated with the order" do
          expect { do_request }
            .to change { order.reload.account }
            .from(account)
            .to(other_account)
        end

        it "updates the account associated with the order_detail" do
          expect { do_request }
            .to change { order_detail.reload.account }
            .from(account)
            .to(other_account)
        end

        it_behaves_like "it uses add_to_cart to determine redirects"
      end

      context "that the user is not allowed to use" do
        let(:other_account) { create(:setup_account) }

        it "does not change the account while flashing an error message" do
          expect { do_request }.not_to change { order.reload.account }
          expect(flash[:error]).to include("error was encountered")
        end
      end
    end

    context "when selecting the same account" do
      before { @params.merge!(account_id: account.id) }

      it "does not change the account associated with the order" do
        expect { do_request }.not_to change { order.reload.account }
      end

      it "does not change the account associated with the order_detail" do
        expect { do_request }.not_to change { order_detail.reload.account }
      end

      it_behaves_like "it uses add_to_cart to determine redirects"
    end
  end

  context "update on purchase" do
    before :each do
      @order_detail = place_product_order(@staff, @authable, @item, @account, false)
      @order = @order_detail.order

      # mimic visiting the cart
      @order.validate_order!

      # setup params
      @action = :purchase
      @method = :put
      @params = { id: @order.id, order_id: @order.id }

      sign_in @staff
    end

    context "update quantity" do
      before :each do
        # setup quantity update params
        @params["quantity#{@order_detail.id}"] = 5
        do_request
      end

      it "updates the quantity", :aggregate_failures do
        @order_detail.reload
        expect(flash[:error]).to include("Quantities have changed")
        expect(@order_detail.quantity).to eq(5)
      end

      it "renders the show view" do
        is_expected.to render_template(:show)
      end

      it { expect(assigns[:order].state).not_to eq("purchased") }
    end

    context "update quantities of multiple items while keeping total the same" do
      before :each do
        # modify first od quantity behind the scenes
        @order_detail1 = @order_detail
        @order_detail1.update_attributes(quantity: 4)

        # add another item
        @order_detail2 = @order_detail1.order.add(@item, 3).first

        # mimic cart being visited
        @order.reload
        @order.validate_order!

        # set new quantities which are swapped in params
        @params["quantity#{@order_detail1.id}"] = @order_detail2.quantity
        @params["quantity#{@order_detail2.id}"] = @order_detail1.quantity

        do_request
      end

      it "updates the quantities" do
        @order_detail1.reload
        expect(@order_detail1.quantity).to eq(3)
        @order_detail2.reload
        expect(@order_detail2.quantity).to eq(4)
      end

      it "has a flash message" do
        expect(flash[:error]).to include("Quantities have changed")
      end

      it "renders the show view" do
        is_expected.to render_template(:show)
      end

      it { expect(assigns[:order].state).not_to eq("purchased") }
    end

    context "update note" do
      before :each do
        # setup note update params (have to also setup quantity params)
        @params["note#{@order_detail.id}"] = "note set on purchase"
        do_request
      end

      it "updates the note" do
        order_detail = assigns[:order].order_details.first
        order_detail.reload
        expect(order_detail.note).not_to be_blank
      end

      it "sets the order state to purchased" do
        @order.reload
        expect(@order.state).to eq("purchased")
      end
    end

    context "remove note" do
      let(:order_detail) { order.order_details.first }
      before do
        order_detail.update_attributes(note: "old note")
        @action = :update
        params["note#{@order_detail.id}"] = ""
      end

      it "removes the note" do
        do_request
        expect(order_detail.reload.note).to be_blank
      end
    end
  end

  context "purchase" do
    before :each do
      @method = :put
      @action = :update_or_purchase
    end

    it_should_require_login

    context "success" do
      before :each do
        @instrument = FactoryBot.create(:instrument,
                                        facility: @authable,
                                        no_relay: true)
        @instrument_pp = create :instrument_price_policy, price_group: @nupg, product: @instrument
        define_open_account(@instrument.account, @account.account_number)
        @reservation = place_reservation_for_instrument(@staff, @instrument, @account, Time.zone.now)
        @order = @reservation.order_detail.order
        expect(@reservation.order_detail.order_status).to be_nil
        @params.merge!(id: @order.id, order_id: @order.id)
      end

      it "sets the order state to purchased" do
        sign_in @staff
        do_request
        expect(assigns[:order].state).to eq("purchased")
      end

      it "sets the order detail status to the product's default status" do
        sign_in @staff
        do_request
        expect(assigns[:order].order_details.size).to eq(1)
        expect(assigns[:order].order_details.first.order_status).to eq(OrderStatus.new_status)
      end

      it "sets the order detail status to the product's default status" do # TODO: reword this so it's not identical to the previous spec
        @order_status = FactoryBot.create(:order_status, parent: OrderStatus.in_process)
        @instrument.update_attributes!(initial_order_status_id: @order_status.id)
        sign_in @staff
        do_request
        expect(assigns[:order].order_details.size).to eq(1)
        expect(assigns[:order].order_details.first.order_status).to eq(@order_status)
      end

      it "redirects to my reservations on a successful purchase of a single reservation" do
        sign_in @staff
        do_request
        expect(flash[:notice]).to eq("Reservation created successfully")
        expect(response).to redirect_to reservations_path
      end

      it "redirects to switch on if the instrument has a relay" do
        @instrument.update_attributes(relay: FactoryBot.create(:relay_dummy, instrument: @instrument))
        sign_in @staff
        do_request
        expect(response).to redirect_to order_order_detail_reservation_switch_instrument_path(
          @order,
          @order_detail,
          @reservation,
          switch: "on",
          redirect_to: reservations_path,
        )
      end

      it "redirects to the receipt when purchasing multiple reservations" do
        @order.add(@instrument, 1)
        expect(@order.order_details.size).to eq(2)
        @reservation2 = FactoryBot.create(:reservation, order_detail: @order.order_details[1], product: @instrument)
        expect(Reservation.all.size).to eq(2)

        sign_in @staff
        do_request
        expect(response).to redirect_to receipt_order_url(@order)
      end

      it "redirects to the receipt when ordering a single reservation as staff" do
        sign_in @admin
        switch_to @staff
        do_request
        expect(response).to redirect_to receipt_order_url(@order)
      end

      describe "emailed receipts" do
        before { sign_in @admin }

        context "when ordering" do
          it "sends receipts" do
            expect(PurchaseNotifier).to receive(:order_receipt).once { DummyNotifier.new }
            do_request
          end
        end

        context "when ordering on behalf of (acting as)" do
          before { switch_to @staff }

          context "when send_notification is checked" do
            before { @params[:send_notification] = "1" }

            it "sends receipts" do
              expect(PurchaseNotifier).to receive(:order_receipt).once { DummyNotifier.new }
              do_request
            end
          end

          context "when send_notification is unchecked" do
            before { @params[:send_notification] = "" }

            it "does not send receipts" do
              expect(PurchaseNotifier).not_to receive(:order_receipt)
              do_request
            end
          end
        end
      end

      describe "emailed order notifications" do
        before { sign_in @admin }

        context "when the facility has an order_notification_recipient" do
          let(:facility) { create(:setup_facility, :with_order_notification) }

          it "sends order notifications" do
            expect(PurchaseNotifier).to receive(:order_notification).once { DummyNotifier.new }
            do_request
          end

          context "when the order was made on behalf of another user" do
            before { switch_to @staff }

            it "does not send order notifications" do
              expect(PurchaseNotifier).not_to receive(:order_notification)
              do_request
            end
          end
        end

        context "when the facility has no order_notification_recipient" do
          it "sends no order notifications" do
            expect(PurchaseNotifier).not_to receive(:order_notification)
            do_request
          end
        end
      end
    end

    context "backdating" do
      before :each do
        @order_detail = place_product_order(@staff, @authable, @item, @account, false)
        @order_detail.update_attribute(:ordered_at, nil)
        @params.merge!(id: @order.id)
      end

      it "sets up state correctly" do
        expect(@order.state).to eq("new")
        expect(@order_detail.state).to eq("new")
      end

      it "validates the order properly" do
        expect(@order).to be_has_details
        expect(@order).to be_has_valid_payment
        expect(@order).to be_cart_valid
      end

      it "validates and places the order" do
        @order.validate_order!
        expect(@order).to be_validated
      end

      it "redirects to the order receipt on a successful purchase" do
        sign_in @staff
        do_request
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to receipt_order_path(@order)
      end

      it "sets ordered_at to a time in the past" do
        maybe_grant_always_sign_in :director
        switch_to @staff
        @params[:order_date] = format_usa_date(1.day.ago)
        @params[:order_time] = { hour: "10", minute: "12", ampm: "AM" }
        do_request
        expect(assigns[:order].order_details.map(&:ordered_at)).to all(match_date 1.day.ago.change(hour: 10, min: 12))
      end

      it "sets ordered_at to now if not acting_as" do
        maybe_grant_always_sign_in :director
        @params[:order_date] = format_usa_date(1.day.ago)
        do_request
        expect(assigns[:order].order_details.map(&:ordered_at)).to all(match_date Time.current)
      end

      it "does not set ordered_at when quantities change" do
        @order.validate_order!
        maybe_grant_always_sign_in :director
        switch_to @staff

        @params.merge!(
          "quantity#{@order_detail.id}" => 5,
          "order_date" => "09/30/2016",
          "order_time" => { "hour" => "4", "minute" => "0", "ampm" => "PM" },
        )
        do_request

        expect(@order.reload.state).not_to eq("purchased")
        expect(@order.order_details.map(&:ordered_at)).to all(be_blank)
      end

      context "setting status of order details" do
        before :each do
          maybe_grant_always_sign_in :director
          switch_to @staff
        end

        it "leaves the order_detail states as new by default" do
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq("new") }
        end

        it "leave the order_detail states as new if new is set as the param" do
          @params[:order_status_id] = OrderStatus.new_status.id
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq("new") }
        end

        it "can set the order_detail states to canceled" do
          @params[:order_status_id] = OrderStatus.canceled.id
          do_request
          assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq("canceled") }
        end

        context "completed" do
          before :each do
            @params.merge!(order_status_id: OrderStatus.complete.id)
          end

          it "can set order_detail states to completed" do
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.state).to eq("complete") }
          end

          context "with no review period", billing_review_period: 0.days do
            before { do_request }
            let(:order_details) { assigns[:order].reload.order_details }

            it { expect(order_details).to all be_reviewed_at }
          end

          context "with a 1 week review period", billing_review_period: 7.days do
            before { do_request }
            let(:order_details) { assigns[:order].reload.order_details }

            it { expect(order_details).not_to include(be_reviewed_at) }
          end

          it "sets the order_detail fulfilled dates to the order time" do
            @item_pp = @item.item_price_policies.create!(FactoryBot.attributes_for(:item_price_policy, price_group_id: @price_group.id, start_date: 1.day.ago, expire_date: 1.day.from_now))
            @params[:order_date] = format_usa_date(1.day.ago)
            @params[:order_time] = { hour: "10", minute: "13", ampm: "AM" }
            do_request
            assigns[:order].reload.order_details.all? { |od| expect(od.fulfilled_at).to match_date 1.day.ago.change(hour: 10, min: 13) }
          end

          context "price policies" do
            before :each do
              @item.item_price_policies.clear
              @item_pp = @item.item_price_policies.create!(FactoryBot.attributes_for(:item_price_policy, price_group_id: @price_group.id, start_date: 1.day.ago, expire_date: 1.day.from_now))
              @item_past_pp = @item.item_price_policies.create!(FactoryBot.attributes_for(:item_price_policy, price_group_id: @price_group.id, start_date: 7.days.ago, expire_date: 1.day.ago))
              @params.merge!(order_time: { hour: "10", minute: "00", ampm: "AM" })
            end

            it "uses the current price policy if the order date falls in the policy's date range" do
              @params[:order_date] = format_usa_date(1.day.ago)
              do_request
              assigns[:order].reload.order_details.all? { |od| expect(od.price_policy).to eq(@item_pp) }
            end

            it "uses an old price policy if the order date falls in the old policy's date range" do
              @params[:order_date] = format_usa_date(5.days.ago)
              do_request
              assigns[:order].reload.order_details.all? { |od| expect(od.price_policy).to eq(@item_past_pp) }
            end

            # when backdating was initially set up, this would cause an error, but behavior changed as of ticket #51239
            it "does not error if there is no policy set for the date in the past" do
              @params[:order_date] = format_usa_date(9.days.ago)
              do_request
              assigns[:order].reload.order_details.all? do |od|
                expect(od.price_policy).to be_nil
                expect(od.actual_cost).to be_nil
                expect(od.actual_subsidy).to be_nil
                expect(od.state).to eq("complete")
              end
              expect(flash[:error]).to be_nil
              expect(response).to redirect_to receipt_order_url(@order)
            end
          end
        end
      end

      context "backdating a reservation" do
        let(:reservation) { place_reservation_for_instrument(@staff, instrument, @account, 3.days.ago) }
        let(:submitted_date) { 2.days.ago.change(hour: 14, min: 27) }

        def setup_past_reservation
          @instrument_pp = create :instrument_price_policy, price_group: @price_group, start_date: 7.days.ago, expire_date: 1.day.from_now, product: instrument
          define_open_account(instrument.account, @account.account_number)
          expect(reservation).not_to be_nil
          @params[:id] = reservation.order_detail.order.id
          maybe_grant_always_sign_in :director
          switch_to @staff
          @params[:order_date] = format_usa_date(2.days.ago)
          @params[:order_time] = { hour: "2", minute: "27", ampm: "PM" }
        end

        context "for a reservation-only instrument" do
          let(:instrument) { FactoryBot.create(:setup_instrument, facility: facility) }

          before { setup_past_reservation }

          it "does not set the actual times to the completed reservation times" do
            do_request
            expect(reservation.reload.actual_start_at).to be_nil
            expect(reservation.actual_end_at).to be_nil
          end
        end

        context "for a non reservation-only instrument" do
          let(:instrument) { FactoryBot.create(:setup_instrument, :timer, facility: facility) }

          before { setup_past_reservation }

          it "sets the order_detail states to completed because it's in the past" do
            do_request
            expect(assigns[:order].order_details).to all(be_complete)
          end

          it "sets the order_detail fulfilment dates to the order time" do
            do_request
            assigns[:order].order_details.all? do |od|
              expect(od.fulfilled_at).not_to be_nil
              expect(od.fulfilled_at).to match_date reservation.reserve_end_at
            end
          end

          it "sets the actual times to the completed reservation times" do
            do_request
            expect(reservation.reload.actual_start_at).to match_date reservation.reserve_start_at
            expect(reservation.actual_end_at).to match_date(reservation.reserve_start_at + 60.minutes)
          end

          it "assigns a price policy and cost" do
            do_request
            expect(@order_detail.reload.price_policy).not_to be_nil
            expect(@order_detail.actual_cost).not_to be_nil
          end

          context "with order status params" do
            before :each do
              @params[:order_status_id] = OrderStatus.canceled.id
              do_request
            end

            it "does not change the reservation order detail state", :aggregate_failures do
              expect(assigns[:order].order_details).to all(be_complete)
              expect(assigns[:order].order_details.first.order_status).to eq OrderStatus.complete
            end
          end
        end
      end
    end
  end

  context "receipt" do
    before :each do
      # for receipt to work, order needs to have order_details
      @complete_order = place_and_complete_item_order(@staff, @authable, @account).order.reload
      @method = :get
      @action = :receipt
      @params = { id: @complete_order.id }
    end

    it_should_require_login

    it_should_allow :staff do
      expect(assigns(:order)).to be_kind_of Order
      expect(assigns(:order)).to eq(@complete_order)
      is_expected.to render_template "receipt"
    end
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
      @params = { status: "pending" }
    end

    it_should_require_login

    it_should_allow :staff do
      expect(assigns(:order_details)).to be_kind_of ActiveRecord::Relation
      is_expected.to render_template "index"
    end
  end

  context "add to cart" do
    before(:each) do
      @method = :put
      @action = :add
      @params[:order] = { order_details: [{ quantity: 1, product_id: @item.id }] }
      @order.clear_cart?
    end

    it_should_require_login

    context "with account (having already gone through choose_account)" do
      before :each do
        @order.account = @account
        @order.save!
        session[:add_to_cart] = nil
      end

      it_should_allow :staff, "to add a product with quantity to cart" do
        expect(assigns(:order).id).to eq(@order.id)
        expect(@order.reload.order_details.count).to eq(1)
        expect(flash[:error]).to be_nil
        expect(response).to redirect_to "/orders/#{@order.id}"
      end

      it_should_allow :staff, "and assign an estimated price if there is a policy" do
        expect(@item.price_policies).not_to be_empty
        expect(@order.reload.order_details.first.estimated_cost).not_to be_nil
      end

    end

    context "instrument" do
      before :each do
        @order.clear_cart?
        @instrument = FactoryBot.create(:instrument,
                                        facility: @authable,
                                        min_reserve_mins: 60,
                                        max_reserve_mins: 60)
        @params[:id] = @order.id
        @params[:order][:order_details].first[:product_id] = @instrument.id
      end

      it_should_allow :staff, "with empty cart (will use same order)" do
        expect(assigns(:order).id).to eq(@order.id)
        expect(flash[:error]).to be_nil

        assert_redirected_to new_order_order_detail_reservation_path(@order.id, @order.reload.order_details.first.id)
      end

      context "quantity = 2" do
        before :each do
          @params[:order][:order_details].first[:quantity] = 2
        end

        it_should_allow :staff, "with empty cart (will use same order) redirect to choose account" do
          expect(assigns(:order).id).to eq(@order.id)
          expect(flash[:error]).to be_nil

          assert_redirected_to choose_account_order_url(@order)
        end

      end

      context "with non-empty cart" do
        before :each do
          @order.add(@item, 1)
        end

        it_should_allow :staff, "with non-empty cart (will create new order)" do
          expect(assigns(:order)).not_to eq(@order)
          expect(flash[:error]).to be_nil

          assert_redirected_to new_order_order_detail_reservation_path(assigns(:order), assigns(:order).order_details.first)
        end
      end
    end

    context "add is called and cart doesn't have an account" do
      before :each do
        @order.account = nil
        @order.save
        maybe_grant_always_sign_in :staff
        do_request
      end

      it { expect(response).to redirect_to("/orders/#{@order.id}/choose_account") }

      it "sets the session with contents of params[:order][:order_details]" do
        expect(session[:add_to_cart]).not_to be_empty
        expect(session[:add_to_cart].map(&:to_h)).to match_array([{ "product_id" => @item.id.to_s, "quantity" => "1" }])
      end
    end

    context "w/ account" do
      before :each do
        @order.account = @account
        @order.save!
      end

      context "mixed facility" do
        it "should flash error message containing another" do # TODO: reword this
          @facility2 = FactoryBot.create(:setup_facility)
          @account2 = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @staff))
          @item2 = FactoryBot.create(:item, facility: @facility2)
          # add first item to cart
          maybe_grant_always_sign_in :staff
          do_request

          # add second item to cart
          @params[:order] = { order_details: [{ quantity: 1, product_id: @item2.id }] }
          do_request

          is_expected.to set_flash.to(/can not/)
          is_expected.to set_flash.to(/another/)
          expect(response).to redirect_to "/orders/#{@order.id}"
        end
      end
    end

    context "acting_as" do
      before :each do
        @order.account = @account
        @order.save!
        @facility2 = FactoryBot.create(:setup_facility)
        @account2 = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @staff))
        @item2 = FactoryBot.create(:item, facility: @facility2)
      end

      context "in the right facility" do
        before :each do
          @params.merge!(order: { order_details: [{ quantity: 1, product_id: @item.id }] })
        end

        facility_operators.each do |role|
          it "allows #{role} to purchase" do
            maybe_grant_always_sign_in role
            switch_to @guest
            do_request
            is_expected.not_to set_flash
            expect(@order.reload.order_details).not_to be_empty
            expect(response).to redirect_to "/orders/#{@order.id}"
          end
        end

        it "does not allow guest" do
          maybe_grant_always_sign_in :guest
          @guest2 = FactoryBot.create(:user)
          switch_to @guest2
          do_request
          is_expected.to set_flash
          expect(@order.reload.order_details).to be_empty
        end
      end

      context "in the another facility" do
        before :each do
          maybe_grant_always_sign_in :director
          switch_to @guest
          @params.merge!(order: { order_details: [{ quantity: 1, product_id: @item2.id }] })
        end

        it "does not allow ordering" do
          do_request
          expect(@order.reload.order_details).to be_empty
          is_expected.to set_flash.to(/You are not authorized to place an order on behalf of another user for the facility/)
        end
      end
    end
  end

  context "remove from cart" do
    before(:each) do
      @order.add(@item, 1)
      expect(@order.order_details.size).to eq(1)
      @order_detail = @order.order_details[0]

      @method = :put
      @action = :remove
      @params.merge!(order_detail_id: @order_detail.id)
    end

    it_should_require_login

    it_should_allow :staff, "and delete an order_detail when /remove/:order_detail_id is called" do
      expect(@order.reload.order_details.size).to eq(0)
      expect(response).to redirect_to "/orders/#{@order.id}"
    end

    it "404s if the order_detail to be removed is not in the current cart" do
      @account2 = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @director))
      @order2   = @director.orders.create(FactoryBot.attributes_for(:order, user: @director, created_by: @director.id, account: @account2))
      @order2.add(@item)
      @order_detail2 = @order2.order_details[0]
      @params[:order_detail_id] = @order_detail2.id
      maybe_grant_always_sign_in :staff
      do_request
      expect(response.response_code).to eq(404)
    end

    context "removing last item in cart" do
      it "nils out the payment source in the order/session" do
        maybe_grant_always_sign_in :staff
        do_request

        expect(response).to redirect_to "/orders/#{@order.id}"
        is_expected.to set_flash.to /removed/

        expect(@order.reload.order_details.size).to eq(0)
        expect(@order.reload.account).to eq(nil)
      end
    end

    it "redirects to the value of the redirect_to param if available" do
      maybe_grant_always_sign_in :staff
      overridden_redirect = facility_url(@item.facility)

      @params[:redirect_to] = overridden_redirect
      do_request

      expect(response).to redirect_to overridden_redirect
      is_expected.to set_flash.to /removed/
    end
  end

  context "update order_detail quantities" do
    before(:each) do
      @method = :put
      @action = :update
      @order_detail = @order.add(@item, 1).first
      @params.merge!("quantity#{@order_detail.id}" => "6")
    end

    it_should_require_login

    it_should_allow :staff, "to update the quantities of order_details" do
      expect(@order_detail.reload.quantity).to eq(6)
    end

    context "bad input" do
      it "errors when quantity is not an integer" do
        @params["quantity#{@order_detail.id}"] = "1.5"
        maybe_grant_always_sign_in :guest
        do_request
        is_expected.to set_flash.to(/quantity/i)
        is_expected.to set_flash.to(/integer/i)
        is_expected.to render_template :show
      end
    end
  end

  context "update order_detail notes" do
    before(:each) do
      @method = :put
      @action = :update
      @order_detail = @order.add(@item, 1).first
      @params.merge!(
        "quantity#{@order_detail.id}" => "6",
        "note#{@order_detail.id}" => "new note",
      )
    end

    it_should_require_login

    it_should_allow :staff, "to update the note field of order_details" do
      expect(@order_detail.reload.note).to eq("new note")
    end
  end

  context "cart meta data" do
    before(:each) do
      @instrument = FactoryBot.create(:instrument,
                                      facility: @authable)

      @instrument.schedule_rules.create(FactoryBot.attributes_for(:schedule_rule, start_hour: 0, end_hour: 24))
      @instrument_pp = @instrument.instrument_price_policies.create(FactoryBot.attributes_for(:instrument_price_policy, price_group_id: @price_group.id))
      @instrument_pp.restrict_purchase = false
      define_open_account(@instrument.account, @account.account_number)
      @service = FactoryBot.create(:service, facility: facility)
      @method = :get
      @action = :show
    end

    it_should_require_login

    context "staff" do
      before :each do
        @order.add(@instrument)
        @order_detail = @order.order_details.first
      end

      it_should_allow :staff, "to show links for making a reservation for instruments" do
        expect(response).to be_successful
      end
    end

    context "restricted instrument" do
      before :each do
        @instrument.update_attributes(requires_approval: true)
        @order.update_attributes(created_by_user: @director, account: @account)
        @order.add(@instrument)
        expect(@order.order_details.size).to eq(1)
        @params.merge!(id: @order.id)
      end

      it "does not allow purchasing a restricted item" do
        maybe_grant_always_sign_in :guest
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        # place reservation makes the @order purchased
        @order.reload.update_attributes!(state: "new")
        do_request
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order]).not_to be_validated
      end

      it "allows purchasing a restricted item the user isn't authorized for" do
        place_reservation(@authable, @order.order_details.first, Time.zone.now)
        # place reservation makes the @order purchased
        @order.reload.update_attributes!(state: "new")
        maybe_grant_always_sign_in :director
        switch_to @guest
        do_request
        expect(response.code).to eq("200")
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order]).to be_validated
      end

      it "is not validated if there is no reservation" do
        maybe_grant_always_sign_in :director
        do_request
        expect(response).to be_successful
        expect(assigns[:order]).not_to be_validated
        expect(assigns[:order]).to eq(@order)
        expect(assigns[:order].order_details.first.validate_for_purchase).to eq("Please make a reservation")
      end
    end
  end

  context "clear" do
    before(:each) do
      @method = :put
      @action = :clear
    end

    it_should_require_login

    it_should_allow :staff, "to clear the cart and redirect back to cart" do
      @order.order_details.size == 0
      assert_redirected_to order_path(@order)
    end
  end

  context "checkout" do
    before(:each) do
      # @item_pp          = FactoryBot.create(:item_price_policy, :item => @item, :price_group => @price_group)
      # @pg_member        = FactoryBot.create(:user_price_group_member, :user => @staff, :price_group => @price_group)
      @order.add(@item, 10)
      @method = :get
      @action = :show
    end

    it_should_require_login

    it "does not allow viewing of a cart that is purchased" do
      FactoryBot.create(:price_group_product, product: @item, price_group: @price_group, reservation_window: nil)
      define_open_account(@item.account, @account.account_number)
      @order.validate_order!
      @order.purchase!
      maybe_grant_always_sign_in :staff
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      @action = :choose_account
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      @method = :put
      @action = :purchase
      do_request
      expect(response).to redirect_to "/orders/#{@order.id}/receipt"

      # TODO: add, etc.
    end

    it "sets the potential order_statuses from this facility and only this facility" do
      maybe_grant_always_sign_in :staff
      @facility2 = FactoryBot.create(:facility)
      @order_status = FactoryBot.create(:order_status, facility: @authable, parent: OrderStatus.new_status)
      @order_status_other = FactoryBot.create(:order_status, facility: @facility2, parent: OrderStatus.new_status)
      do_request
      expect(assigns[:order_statuses]).to be_include @order_status
      expect(assigns[:order_statuses]).not_to be_include @order_status_other
    end
  end
end
