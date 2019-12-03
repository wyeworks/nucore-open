# frozen_string_literal: true

module ReportSpecHelper

  include DateHelper
  include ReportsHelper
  extend ActiveSupport::Concern

  included do |base|
    base.render_views

    base.before(:all) { create_users }

    base.before(:each) do
      @method = :get
      @authable = FactoryBot.create(:facility)
      @action = :index
      @params = {
        facility_id: @authable.url_name,
        date_start: Time.zone.now.strftime("%m/%d/%Y"),
        date_end: (Time.zone.now + 1.year).strftime("%m/%d/%Y"),
        report_by: @report_by,
      }

      setup_extra_params(@params)
    end
  end

  module ClassMethods

    def run_report_tests(tests)
      tests.each do |test|
        context test[:report_by].to_s do
          before :each do
            @params[:report_by] = test[:report_by]
            [:owner, :staff, :purchaser].each do |user|
              acct = create_nufs_account_with_owner user
              place_and_complete_item_order(instance_variable_get("@#{user}"), @authable, acct)
              @order_detail.ordered_at = parse_usa_date(@params[:date_start]) + 15.days
              assert @order.save
              setup_extra_test_data(user)
            end
          end

          it_should_allow_managers_and_senior_staff_only do
            assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
          end

          context "ajax" do
            before :each do
              @method = :xhr
            end

            it_should_allow :director do
              assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
            end
          end

          context "export" do
            before :each do
              @params.merge!(format: :csv)
            end

            it_should_allow :director do
              assert_report_rendered(test[:index], test[:report_on_label], &test[:report_on])
            end
          end
        end
      end
    end

  end

  private

  def setup_extra_params(params)
  end

  def setup_extra_test_data(user)
  end

  def report_headers(_label)
    raise "Including class must implement!"
  end

  def assert_report_init(_label)
    raise "Including class must implement!"
  end

  def export_all_request?
    @params.key?(:export_id) && @params[:export_id] == "report_data"
  end

  def assert_report_params_init
    now = Date.today
    date_start = Date.new(now.year, now.month, 1) - 1.month

    if @params[:date_start].blank?
      expect(assigns(:date_start)).to eq(date_start)
    else
      expect(assigns(:date_start)).to eq(parse_usa_date(@params[:date_start]).beginning_of_day)
    end

    if @params[:date_end].blank?
      date_end = date_start + 42.days
      expect(assigns(:date_end)).to eq(Date.new(date_end.year, date_end.month) - 1.day)
    else
      expect(assigns(:date_end)).to eq(parse_usa_date(@params[:date_end]).end_of_day)
    end
  end

  def assert_report_download_rendered(filename)
    expect(@response.headers["Content-Type"]).to match %r{\Atext/csv\b}
    filename += "_#{assigns(:date_start).strftime('%Y%m%d')}-#{assigns(:date_end).strftime('%Y%m%d')}.csv"
    expect(@response.headers["Content-Disposition"]).to eq("attachment; filename=\"#{filename}\"")
    is_expected.to respond_with :success
  end

  def assert_report_rendered(tab_index, label, &report_on)
    assert_report_params_init
    expect(assigns :headers).to eq report_headers(label)
    expect(assigns :selected_index).to eq tab_index

    format = @params[:format] || :html

    case format
    when :html
      assert_report_rendered_html(label, &report_on)
    when :csv
      assert_report_rendered_csv(label, &report_on)
    end
  end

  def assert_report_rendered_html(label, &report_on)
    if @method == :xhr
      assert_report_init label, &report_on
      is_expected.to render_template "reports/report_table"
    else
      is_expected.to render_template "reports/report"
    end
  end

  def assert_report_rendered_csv(label, &report_on)
    assert_report_init label, &report_on
    assert_report_download_rendered "#{@params[:report_by]}_report"
  end

end
