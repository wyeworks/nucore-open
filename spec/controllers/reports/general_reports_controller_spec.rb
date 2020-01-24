# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "report_spec_helper"

RSpec.describe Reports::GeneralReportsController do
  let(:facility) { @authable }

  include ReportSpecHelper

  run_report_tests([
                     { report_by: :product, index: 0, report_on_label: "Product", report_on: proc { |od| od.product.name } },
                     { report_by: :account, index: 1, report_on_label: "Account", report_on: proc { |od| od.account } },
                     { report_by: :account_owner, index: 2, report_on_label: "Account Owner", report_on: proc { |od| owner = od.account.owner.user; "#{owner.last_name}, #{owner.first_name} (#{owner.username})" } },
                     { report_by: :purchaser, index: 3, report_on_label: "Purchaser", report_on: proc { |od| usr = od.order.user; "#{usr.last_name}, #{usr.first_name} (#{usr.username})" } },
                     { report_by: :price_group, index: 4, report_on_label: "Price Group", report_on: proc { |od| od.price_policy ? od.price_policy.price_group.name : "Unassigned" } },
                   ])

  describe "time parameters", :time_travel do
    let(:now) { Time.zone.parse("2014-03-06 12:00") }

    before do
      allow(controller).to receive(:authenticate_user!).and_return true
      allow(controller).to receive(:current_facility).and_return build_stubbed(:facility)
    end

    context "defaults" do
      before { get :index, params: { facility_id: facility.url_name, report_by: :product } }

      it "assigns the proper start date" do
        expect(assigns(:date_start)).to eq(Time.zone.local(2014, 2, 1))
      end

      it "assigns the proper end date" do
        expect(assigns(:date_end).to_i).to eq(Time.zone.local(2014, 2, 28, 23, 59, 59).to_i)
      end
    end

    context "with date parameters" do
      before { get :index, params: { facility_id: facility.url_name, report_by: :product, date_start: "01/01/2014", date_end: "01/31/2014" } }

      it "assigns the start date to the beginning of the day" do
        expect(assigns(:date_start)).to eq(Time.zone.local(2014, 1, 1))
      end

      it "assigns the end date to the end of the day" do
        expect(assigns(:date_end).to_i).to eq(Time.zone.local(2014, 1, 31, 23, 59, 59).to_i)
      end
    end
  end

  context "report searching" do
    before :each do
      @complete = OrderStatus.complete

      @user = FactoryBot.create(:user)
      @authable = FactoryBot.create(:setup_facility)
      @item = FactoryBot.create(:item, facility: @authable)

      @account = create_nufs_account_with_owner :user
      define_open_account @item.account, @account.account_number

      @order_detail_ordered_today_unfulfilled = place_product_order(@user, @authable, @item, @account)

      @order_detail_ordered_yesterday_unfulfilled = place_product_order(@user, @authable, @item, @account)
      @order_detail_ordered_yesterday_unfulfilled.update_attributes!(ordered_at: 1.day.ago)

      @order_detail_ordered_yesterday_fulfilled_today_unreconciled = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_today_unreconciled.update_attributes!(ordered_at: 1.day.ago)

      @order_detail_ordered_today_fulfilled_today_unreconciled = place_and_complete_item_order(@user, @authable, @account)

      @order_detail_ordered_today_fulfilled_next_month_unreconciled = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_today_fulfilled_next_month_unreconciled.update_attributes(fulfilled_at: 1.month.from_now)

      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today.update_attributes!(ordered_at: 1.day.ago, fulfilled_at: 1.day.ago)
      @journal_today = FactoryBot.create(:journal, facility: @authable, created_by: @admin.id, journal_date: Time.zone.now)
      @journal_today.create_journal_rows!([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today])
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today.change_status!(OrderStatus.reconciled)

      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday = place_and_complete_item_order(@user, @authable, @account)
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday.update_attributes(ordered_at: 1.day.ago, fulfilled_at: 1.day.ago)
      @journal_yesterday = FactoryBot.create(:journal, facility: @authable, created_by: @admin.id, journal_date: 1.day.ago)
      @journal_yesterday.create_journal_rows!([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday])
      @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday.change_status!(OrderStatus.reconciled)

      @method = :xhr
      @action = :index
      @params = {
        report_by: :product,
        facility_id: @authable.url_name,
        date_start: Time.zone.now.strftime("%m/%d/%Y"),
        date_end: 1.day.from_now.strftime("%m/%d/%Y"),
      }

      sign_in @admin
    end

    context "ordered_at search" do
      before :each do
        @params.merge!(date_range_field: :ordered_at)
      end

      it "should search" do
        do_request
        expect(response).to be_successful
      end

      it "should search search unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_status.id]
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_today_unfulfilled]
      end

      it "should search fulfilled" do
        @params[:status_filter] = [@complete.id]
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_today_fulfilled_today_unreconciled, @order_detail_ordered_today_fulfilled_next_month_unreconciled]
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        do_request
        expect(assigns[:report_data]).to be_none
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today]
      end
    end

    context "fulfilled_at search" do
      before :each do
        @params.merge!(date_range_field: :fulfilled_at)
      end

      it "should have a problem if it searches unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_status.id]
        do_request
        expect(assigns[:report_data]).to be_none
      end

      it "should search fulfilled" do
        @params[:status_filter] = [@complete.id]
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_yesterday_fulfilled_today_unreconciled, @order_detail_ordered_today_fulfilled_today_unreconciled]
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        do_request
        expect(assigns[:report_data].to_a).to be_none
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today]
      end
    end

    context "journaled_at search" do
      before :each do
        # change start date so we get an order detail
        @params.merge!(date_range_field: :journal_date)
      end

      it "should have a problem if it searches unfulfilled" do
        @params[:status_filter] = [OrderStatus.new_status.id]
        do_request
        expect(assigns[:report_data]).to be_none
      end

      it "should have a problem if it searches unjournaled" do
        @params[:status_filter] = [@complete.id]
        do_request
        expect(assigns[:report_data]).to be_none
      end

      it "should search reconciled" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        do_request
        expect(assigns[:report_data].to_a).to eq([@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today])
      end

      it "should find reconciled that started yesterday" do
        @params[:status_filter] = [OrderStatus.reconciled.id]
        @params[:date_start] = 1.day.ago.strftime("%m/%d/%Y")
        do_request
        expect(assigns[:report_data].to_a).to contain_all [@order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_today, @order_detail_ordered_yesterday_fulfilled_yesterday_reconciled_yesterday]
      end
    end
  end

  describe "an invalid report type" do
    let(:user) { FactoryBot.create(:user, :administrator) }
    before { sign_in user }

    it "returns a 404" do
      get :index, params: { report_by: "asdfasdf", facility_id: facility.url_name }
      expect(response.code).to eq("404")
    end

    it "returns a 404 for a blank report_by" do
      get :index, params: { facility_id: facility.url_name, report_by: "" }
      expect(response.code).to eq("404")
    end
  end

  private

  def setup_extra_params(params)
    params.merge!(status_filter: [OrderStatus.complete.id], date_range_field: "fulfilled_at")
  end

  def report_headers(label)
    [label, "Quantity", "Total Cost", "Percent of Cost"]
  end

  def assert_report_params_init
    super
    expect(assigns(:status_ids)).to be_instance_of Array

    stati = if @params[:date_start].blank? && @params[:date_end].blank?
              [OrderStatus.complete, OrderStatus.reconciled]
            elsif @params[:status_filter].blank?
              []
            else
              @params[:status_filter].collect { |si| OrderStatus.find(si.to_i) }
            end

    status_ids = []

    stati.each do |stat|
      status_ids << stat.id
      status_ids += stat.children.collect(&:id) if stat.root?
    end

    expect(assigns(:status_ids)).to eq(status_ids)
  end

  def assert_report_init(_label)
    expect(response).to be_successful
    expect(assigns(:total_quantity)).to be_kind_of(Integer)

    rows = assigns(:rows)
    ods = OrderDetail.all.to_a
    expect(rows.size).to eq(ods.size)

    rows.each do |row|
      expect(row).to be_instance_of Array
      expect(row.size).to eq(4)
    end

    ods.sort! { |a, b| yield(a) <=> yield(b) }

    ods.each_with_index do |od, i|
      expect(rows[i][0].to_s).to eq(yield(od).to_s)
      expect(rows[i][1]).to eq(od.quantity)
      expect(rows[i][2]).to eq(od.total.to_i)
      expect(rows[i][3]).to eq(to_percent(od.total / assigns(:total_cost)))
    end
  end

end
