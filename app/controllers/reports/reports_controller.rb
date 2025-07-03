# frozen_string_literal: true

module Reports

  class ReportsController < ApplicationController

    include ReportsHelper
    include CSVHelper

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_report_params

    load_and_authorize_resource class: ReportsController

    delegate :reports, :format_username, to: "self.class"

    helper_method :export_raw_visible?

    def initialize
      @active_tab = "admin_reports"
      super
    end

    def index
      @report_by = params[:report_by].presence
      index = reports.keys.find_index(@report_by)
      raise ActionController::RoutingError, "Invalid report_by" unless index
      render_report(index + tab_offset, &reports[@report_by])
    end

    def self.format_username(user)
      Users::NamePresenter.new(user, username_label: true).last_first_name
    end

    def export_raw_visible?
      true
    end

    protected

    def tab_offset
      0
    end

    def report_by_header
      text(@report_by, default: @report_by.titleize)
    end

    private

    def xhr_html_template
      "reports/report_table"
    end

    def init_report_params
      @date_start = parse_usa_date(params[:date_start])
      @date_start = if @date_start.blank?
                      (Time.zone.now - 1.month).beginning_of_month
                    else
                      @date_start.beginning_of_day
                    end

      @date_end = parse_usa_date(params[:date_end])
      @date_end = if @date_end.blank?
                    @date_start.end_of_month
                  else
                    @date_end.end_of_day
                  end
    end

    def init_report
      raise "Subclass must implement!"
    end

    def init_report_data
      raise "Subclass must implement!"
    end

    def init_report_headers
      raise "Subclass must implement!"
    end

    def page_report(rows)
      # Don't paginate reports if we're exporting
      @rows = if params[:export_id].present?
                rows
              else
                rows.paginate(page: params[:page], per_page: 25)
              end
    end

    def render_report(tab_index, &)
      @selected_index = tab_index
      init_report_headers

      respond_to do |format|
        format.html do
          if request.xhr?
            init_report(&)
            render template: xhr_html_template, layout: false
          else
            render template: html_template
          end
        end

        format.csv do
          init_report(&)
          render_csv("#{@report_by}_report")
        end
      end
    end

    def html_template
      "reports/report"
    end

    def render_csv(filename)
      filename += "_#{@date_start.strftime('%Y%m%d')}-#{@date_end.strftime('%Y%m%d')}.csv"
      set_csv_headers(filename)
      render template: "reports/report", layout: false
    end

  end

end
