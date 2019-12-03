# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "order_detail_batch_update_shared_examples"

RSpec.describe FacilityReservationsController do
  include DateHelper

  let(:account) { @account }
  let(:facility) { @authable }
  let(:product) { @product }
  let(:schedule_rule) { @schedule_rule }

  render_views

  before(:all) { create_users }

  before(:each) do
    @authable = FactoryBot.create(:facility)
    @facility_account = FactoryBot.create(:facility_account, facility: @authable)
    @product = FactoryBot.create(:instrument,
                                 facility_account: @facility_account,
                                 facility: @authable,
                                )
    @schedule_rule = FactoryBot.create(:schedule_rule, product: @product)
    @product.reload
    @account = create_nufs_account_with_owner :director
    @order = FactoryBot.create(:order,
                               facility: @authable,
                               user: @director,
                               created_by: @director.id,
                               account: @account,
                               state: "purchased",
                              )

    @reservation = FactoryBot.create(:reservation, product: @product)
    expect(@reservation).not_to be_new_record
    @order_detail = create(:order_detail, account: account, order: @order, product: product, reservation: @reservation)
    @order_detail.set_default_status!
    @params = { facility_id: @authable.url_name, order_id: @order.id, order_detail_id: @order_detail.id, id: @reservation.id }
  end

  context "#assign_price_policies_to_problem_orders" do
    let(:order_details) { [@order_detail] }
    let(:order_detail_ids) { order_details.map(&:id) }

    before :each do
      @method = :post
      @action = :assign_price_policies_to_problem_orders

      start_time = 1.week.ago + schedule_rule.start_hour
      end_time = start_time + 1.hour

      order_details.each do |order_detail|
        order_detail.reservation.update_attributes(
          reserve_start_at: start_time,
          reserve_end_at: end_time,
          actual_start_at: start_time,
          actual_end_at: end_time,
        )
        order_detail.backdate_to_complete!
      end
    end

    context "when compatible price policies exist" do
      let(:price_group) { create(:price_group, facility: facility) }

      before :each do
        create(:account_price_group_member, account: account, price_group: price_group)

        order_details.first.product.instrument_price_policies.create(attributes_for(
                                                                       :instrument_price_policy, price_group_id: price_group.id))

        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: false).count)
          .to eq order_details.count
      end
    end

    context "when no compatible price policies exist" do
      before :each do
        InstrumentPricePolicy.all.each(&:destroy)
        do_request
      end

      it_should_allow_operators_only :redirect do
        expect(OrderDetail.where(id: order_detail_ids, problem: true).count)
          .to eq order_details.count
      end
    end
  end

  it_behaves_like "it supports order_detail POST #batch_update"

  describe "POST #create" do
    let(:admin_reservation_params) do
      {
        reserve_start_date: reserve_start_at.strftime("%m/%d/%Y"),
        reserve_start_hour: reserve_start_at.hour.to_s,
        reserve_start_min: reserve_start_at.strftime("%M"),
        reserve_start_meridian: reserve_start_at.strftime("%p"),
        duration_mins: "60",
        admin_note: "Testing",
      }
    end
    let(:reserve_start_at) { 1.hour.from_now.change(sec: 0) }

    before(:each) do
      @method = :post
      @action = :create
      @params = {
        facility_id: facility.url_name,
        instrument_id: product.url_name,
        admin_reservation: admin_reservation_params,
      }
    end

    it_should_allow_operators_only(:redirect) {}

    context "when signed in as a facility director" do
      before { maybe_grant_always_sign_in :director }

      context "when the reservation is valid" do

        it "sets admin_note" do
          do_request
          expect(assigns[:reservation].admin_note).to eq "Testing"
        end

        it "sets created_by" do
          do_request
          expect(assigns[:reservation].created_by).to eq @director
        end

        it "saves it" do
          expect { do_request }.to change(Reservation, :count).by(1)
        end
      end

      context "when the reservation is invalid" do
        let(:admin_reservation_params) do
          {
            reserve_start_date: reserve_start_at.strftime("%m/%d/%Y"),
            reserve_start_hour: reserve_start_at.hour.to_s,
            reserve_start_min: reserve_start_at.strftime("%M"),
            reserve_start_meridian: reserve_start_at.strftime("%p"),
            duration_mins: "0", # 0 minute duration causes it to be invalid
            admin_note: "Testing",
          }
        end

        it "does not save the reservation", :aggregate_failures do
          expect { do_request }.not_to change(Reservation, :count)
        end
      end
    end
  end

  context "#index" do
    before :each do
      @method = :get
      @action = :index
    end

    it_should_allow_operators_only {}

    context "once signed in" do
      before :each do
        sign_in(@admin)
      end

      it "should not return non-reservation order details" do
        # setup_reservation overwrites @order_detail
        @order_detail_reservation = @order_detail

        @product = FactoryBot.create(:item, facility_account: @facility_account, facility: @authable)
        @order_detail_item = place_product_order(@director, @authable, @product, @account)
        @order_detail.order.update_attributes!(state: "purchased")

        expect(@authable.reload.order_details).to contain_all [@order_detail_reservation, @order_detail_item]
        do_request
        expect(assigns[:order_details]).to eq([@order_detail_reservation])
      end

    end
  end

  context "#new" do
    before :each do
      @method = :get
      @action = :new
      @params = { facility_id: @authable.url_name, instrument_id: @product.url_name }
    end

    it_should_allow_operators_only
  end

  context "#show" do
    before :each do
      @method = :get
      @action = :show
    end

    it_should_allow_operators_only
  end

  context "#show_problems" do
    skip "TODO test exists for the FacilityOrdersController version"
  end

  context "#timeline" do
    context "instrument listing" do
      before :each do
        @instrument2 = FactoryBot.create(:instrument,
                                         facility_account: @facility_account,
                                         facility: @authable,
                                         is_hidden: true)
        maybe_grant_always_sign_in :director
        @method = :get
        @action = :timeline
        @params = { facility_id: @authable.url_name }
      end

      it "should show schedules for hidden instruments" do
        do_request
        expect(assigns(:schedules)).to match_array([@product.schedule, @instrument2.schedule])
      end

      it "defaults the display date to today" do
        do_request
        expect(assigns[:display_datetime]).to eq(Time.current.beginning_of_day)
      end

      it "parses the date" do
        @params[:date] = "6/14/2015"
        do_request
        expect(assigns[:display_datetime]).to eq(Time.zone.parse("2015-06-14T00:00"))
      end

      it "shows relay status toggles when the date is today" do
        allow_any_instance_of(Instrument).to receive(:has_real_relay?).and_return(true)
        do_request
        expect(response.body).to include("relay_checkbox")
      end

      it "does not show relay status toggles when the date is not today" do
        @params[:date] = "6/14/2015"
        allow_any_instance_of(Instrument).to receive(:has_real_relay?).and_return(true)
        do_request
        expect(response.body).not_to include("relay_checkbox")
      end
    end

    context "orders" do
      before :each do
        # create unpurchased reservation
        @order2 = FactoryBot.create(:order,
                                    facility: @authable,
                                    user: @director,
                                    created_by: @director.id,
                                    account: @account,
                                    state: "new",
                                   )
        # make sure the reservations are happening today
        @reservation.update_attributes!(reserve_start_at: Time.zone.now, reserve_end_at: 1.hour.from_now)

        @unpurchased_reservation = FactoryBot.create(:reservation, product: @product, reserve_start_at: 1.hour.from_now, reserve_end_at: 2.hours.from_now)
        @order_detail2 = FactoryBot.create(:order_detail, order: @order2, product: @product, reservation: @unpurchased_reservation)

        @canceled_reservation = FactoryBot.create(:reservation, product: @product, reserve_start_at: 2.hours.from_now, reserve_end_at: 3.hours.from_now)
        @order_detail3 = FactoryBot.create(:order_detail, order: @order, product: @product, reservation: @canceled_reservation)
        expect(@canceled_reservation).to be_persisted
        @order_detail3.update_order_status! @admin, OrderStatus.canceled

        @admin_reservation = FactoryBot.create(
          :admin_reservation,
          product: @product,
          reserve_start_at: Time.zone.now,
          reserve_end_at: 1.hour.from_now,
        )

        maybe_grant_always_sign_in :director
        @method = :get
        @action = :timeline
        @params = { facility_id: @authable.url_name }
        do_request
      end

      it "should not be admin reservations" do
        expect(@reservation).not_to be_admin
        expect(@unpurchased_reservation).not_to be_admin
        expect(@admin_reservation).to be_admin
      end

      it "should show reservation" do
        expect(response.body).to include "id='tooltip_reservation_#{@reservation.id}'"
      end

      it "should not show unpaid reservation" do
        expect(response.body).not_to include "id='tooltip_reservation_#{@unpurchased_reservation.id}'"
      end

      it "should include canceled reservation" do
        expect(response.body).to include "id='tooltip_reservation_#{@canceled_reservation.id}'"
      end

      it "should include admin reservation" do
        expect(response.body).to include "id='tooltip_admin_reservation_#{@admin_reservation.id}'"
      end
    end
  end

  context "#update" do
    let(:reserve_start_at) { FactoryBot.attributes_for(:reservation)[:reserve_start_at] }
    let(:reservation_params) do
      {
        reserve_start_date: reserve_start_at.strftime("%m/%d/%Y"),
        reserve_start_hour: reserve_start_at.hour.to_s,
        reserve_start_min: reserve_start_at.strftime("%M"),
        reserve_start_meridian: reserve_start_at.strftime("%p"),
        duration_mins: "45",
      }
    end

    before :each do
      @method = :put
      @action = :update
      @params.merge!(reservation: reservation_params)
    end

    it_should_allow_operators_only do
      expect(assigns(:order)).to eq(@order)
      expect(assigns(:order_detail)).to eq(@order_detail)
      expect(assigns(:reservation)).to eq(@reservation)
      expect(assigns(:instrument)).to eq(@product)
    end

    context "updating reservation length before complete" do
      before :each do
        expect(@order_detail.price_policy).to be_nil
        @order_detail.account = @account
        @order_detail.save!
        @price_group = FactoryBot.create(:price_group, facility: @authable)
        create(:account_price_group_member, account: account, price_group: @price_group)
        @instrument_pp = @product.instrument_price_policies.create(FactoryBot.attributes_for(:instrument_price_policy, price_group_id: @price_group.id))
        @instrument_pp.reload.restrict_purchase = false
        @reservation.update_attributes(actual_start_at: nil, actual_end_at: nil)
        @params.merge!(reservation: {
                         reserve_start_at: @reservation.reserve_start_at,
                         reserve_end_at: @reservation.reserve_end_at - 15.minutes,
                       },
                      )
      end

      it "should update estimated cost" do
        maybe_grant_always_sign_in :director
        do_request
        # In rails 3.1, assigning the same value is still triggering
        # attr_will_change! so this breaks:
        # assigns[:reservation].should_not be_reserve_start_at_changed
        expect(assigns[:reservation].reserve_start_at).to eq(assigns[:reservation].reserve_start_at_was)
        expect(assigns[:reservation]).to be_reserve_end_at_changed
        expect(assigns[:order_detail]).to be_estimated_cost_changed
      end
    end
  end

  describe "#tab_counts" do
    before(:each) do
      @method = :get
      @action = :tab_counts
      @params.merge!(tabs: %w(new_or_in_process_orders problem_order_details))
    end

    it_should_allow_operators_only
    # TODO: more complete tests exist for the FacilityOrdersController version
  end

  context "admin" do
    let(:admin_reservation) { create(:admin_reservation, product: @product) }

    before do
      @reservation = admin_reservation
      @params = { facility_id: @authable.url_name, instrument_id: @product.url_name, reservation_id: @reservation.id }
    end

    context "#edit_admin" do
      before :each do
        @method = :get
        @action = :edit_admin
      end

      it_should_allow_operators_only
    end

    context "#update_admin" do
      let(:reserve_start_at) { FactoryBot.attributes_for(:admin_reservation)[:reserve_start_at] }
      let(:admin_reservation_params) do
        {
          reserve_start_date: reserve_start_at.strftime("%m/%d/%Y"),
          reserve_start_hour: reserve_start_at.hour.to_s,
          reserve_start_min: reserve_start_at.strftime("%M"),
          reserve_start_meridian: reserve_start_at.strftime("%p"),
          duration_mins: "45",
          admin_note: "Testing",
        }
      end

      before :each do
        @method = :patch
        @action = :update_admin
        @params.merge!(admin_reservation: admin_reservation_params)
      end

      it_should_allow_operators_only :redirect
    end
  end
end
