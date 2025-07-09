# frozen_string_literal: true

module Reports

  class GeneralReportsController < ReportsController

    helper_method(:export_csv_report_path)

    include StatusFilterParams

    def self.reports
      @reports ||= ActiveSupport::HashWithIndifferentAccess.new(
        product: :product,
        account: :account,
        account_owner: lambda do |od|
          # Space at beginning is intentional to bubble it to the top of the list
          od.account.owner_user ? format_username(od.account.owner_user) : " Missing Owner for #{od.account.account_number}"
        end,
        purchaser: ->(od) { format_username od.order.user },
        price_group: ->(od) { od.price_policy ? od.price_policy.price_group.name : text("unassigned") },
        assigned_to: ->(od) { od.assigned_user.presence ? format_username(od.assigned_user) : text("unassigned") },
        project: ->(order_detail) { order_detail.project || " No Project" },
      )
    end

    def export_csv_report_path
      facility_export_raw_reports_path(format: :csv)
    end

    private

    def init_report_headers
      @headers = [report_by_header, text("quantity"), text("total_cost"), text("percent")]
    end

    def init_report_data
      @report_data = report_data
    end

    def init_report(&)
      sums = {}
      rows = []
      @total_quantity = 0
      @total_cost = 0.0
      report_data.each do |od|
        key = instance_exec(od, &)

        key = "Undefined" if key.blank?

        sums[key] = [0, 0] unless sums.key?(key)
        sums[key][0] += od.quantity
        @total_quantity += od.quantity

        total = od.total
        # total can be nil, in which case don't add to cost
        # stats. Report remains true but can appear off since
        # quantity goes up but not cost.
        if total
          sums[key][1] += total
          @total_cost += total
        end
      end

      sums.each do |k, v|
        percent_cost = to_percent(@total_cost > 0 ? v[1] / @total_cost : 1)
        rows << v.push(percent_cost).unshift(k)
      end

      rows.sort! { |a, b| a.first.to_s <=> b.first.to_s }

      page_report(rows)
    end

    def report_data
      @report_data = report_data_query(@status_ids, @date_range_field)
    end

    def report_data_query(order_status_id, date_range_field)
      Reports::Querier.new(
        order_status_id: order_status_id,
        current_facility: current_facility,
        date_range_field: date_range_field,
        date_range_start: @date_start,
        date_range_end: @date_end,
        batch_size: 5_000,
      ).perform
    end

  end

end
