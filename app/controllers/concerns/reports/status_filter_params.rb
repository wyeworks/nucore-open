# frozen_string_literal: true

module Reports
  module StatusFilterParams
    extend ActiveSupport::Concern

    included do
      before_action :init_status_filter_report_params
    end

    def init_status_filter_report_params
      status_ids = Array(params[:status_filter])
      stati = if params[:date_start].blank? && params[:date_end].blank?
                # page load -- default to most interesting/common statuses
                [OrderStatus.complete, OrderStatus.reconciled]
              elsif status_ids.blank?
                # user removed all status filters. They will get nothing back but that's what they want!
                []
              else
                # user filters
                status_ids.reject(&:blank?).collect { |si| OrderStatus.find(si.to_i) }
              end

      @status_ids = []

      stati.each do |stat|
        @status_ids << stat.id
        @status_ids += stat.children.collect(&:id) if stat.root?
      end

      @date_range_field = params[:date_range_field] || "journal_or_statement_date"
    end
  end
end
