# frozen_string_literal: true

require "csv"

module Reports

  class ExportRaw

    include CsvExporter

    attr_reader :order_status_ids, :facility_url_name, :date_range_field

    def initialize(arguments)
      [:date_end, :date_start, :facility_url_name, :order_status_ids].each do |property|
        if arguments[property].present?
          instance_variable_set("@#{property}".to_sym, arguments[property])
        else
          raise ArgumentError, "Required argument '#{property}' is missing"
        end
      end
      @date_range_field = arguments[:date_range_field] || "journal_or_statement_date"
    end

    def facility
      @facility ||= if facility_url_name == Facility.cross_facility.url_name
                      Facility.cross_facility
                    else
                      Facility.find_by(url_name: facility_url_name)
                    end
    end

    def description
      "#{facility.name} Export Raw, #{formatted_date_range}"
    end

    def translation_scope
      "controllers.general_reports"
    end

    private

    def default_report_hash # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      hash = {
        facility: :facility,
        order: :to_s,
        ordered_at: :ordered_at,
        fulfilled_at: ->(od) { od.fulfilled_at },
        order_status: ->(od) { od.order_status.name },
        order_state: :state,
        ordered_by: ->(od) { od.created_by_user.username },
        first_name: ->(od) { od.created_by_user.first_name },
        last_name: ->(od) { od.created_by_user.last_name },
        email: ->(od) { od.created_by_user.email },
        purchaser: ->(od) { od.user.username },
        purchaser_first_name: ->(od) { od.user.first_name },
        purchaser_last_name: ->(od) { od.user.last_name },
        purchaser_email: ->(od) { od.user.email },
        product_id: ->(od) { od.product.url_name },
        product_type: ->(od) { od.product.class.model_name.human },
        product: ->(od) { od.product.name },
        quantity: :quantity,
        bundle: ->(od) { od.bundle.name if od.bundled? },
        account_type: ->(od) { od.account.type.underscore.humanize },
        affiliate: ->(od) { od.account.affiliate_to_s },
        account: ->(od) { od.account.account_number },
        account_description: ->(od) { od.account.description_to_s },
        account_expiration: ->(od) { od.account.expires_at },
        account_owner: ->(od) { od.account.owner_user.username },
        owner_first_name: ->(od) { od.account.owner_user.first_name },
        owner_last_name: ->(od) { od.account.owner_user.last_name },
        owner_email: ->(od) { od.account.owner_user.email },
        price_group: ->(od) { od.price_policy.try(:price_group).try(:name) },
        charge_for: ->(od) { ChargeMode.for_order_detail(od).to_s.titleize },
        estimated_cost: ->(od) { as_currency(od.estimated_cost) },
        estimated_subsidy: ->(od) { as_currency(od.estimated_subsidy) },
        estimated_total: ->(od) { as_currency(od.estimated_total) },
        calculated_cost: ->(od) { as_currency(od.calculated_cost) },
        calculated_subsidy: ->(od) { as_currency(od.calculated_subsidy) },
        calculated_total: ->(od) { as_currency(od.calculated_total) },
        actual_cost: ->(od) { as_currency(od.actual_cost) },
        actual_subsidy: ->(od) { as_currency(od.actual_subsidy) },
        actual_total: ->(od) { as_currency(od.actual_total) },
        difference_cost: ->(od) { as_currency_difference(od.actual_cost, od.calculated_cost) },
        difference_subsidy: ->(od) { as_currency_difference(od.actual_subsidy, od.calculated_subsidy) },
        difference_total: ->(od) { as_currency_difference(od.actual_total, od.calculated_total) },
        reservation_start_time: ->(od) { od.reservation.reserve_start_at if od.reservation },
        reservation_end_time: ->(od) { od.reservation.reserve_end_at if od.reservation },
        reservation_minutes: ->(od) { od.time_data.try(:duration_mins) },
        actual_start_time: ->(od) { od.time_data.actual_start_at if od.time_data.present? },
        actual_end_time: ->(od) { od.time_data.actual_end_at if od.time_data.present? },
        actual_minutes: ->(od) { od.time_data.actual_duration_mins if od.time_data.present? },
        canceled_at: :canceled_at,
        canceled_by: ->(od) { canceled_by_name(od) },
        note: :note,
        disputed_at: :dispute_at,
        dispute_reason: :dispute_reason,
        dispute_resolved_at: :dispute_resolved_at,
        dispute_resolved_reason: :dispute_resolved_reason,
        reviewed_at: :reviewed_at,
        statemented_on: ->(od) { od.statement.created_at if od.statement },
        invoice_number: ->(od) { od.statement.try(:invoice_number) },
        journal_date: ->(od) { od.journal.journal_date if od.journal },
        reconciled_note: :reconciled_note,
        reconciled_at: :reconciled_at,
        price_change_reason: :price_change_reason,
        price_changed_by_user: ->(od) { od.price_changed_by_user&.full_name(suspended_label: false) },
        assigned_staff: ->(od) { od.assigned_user&.full_name(suspended_label: false) },
        billable_minutes: ->(od) { od.time_data.try(:billable_minutes) },
        problem_resolved_at: :problem_resolved_at,
        problem_description_key_was: :problem_description_key_was,
        problem_resolved_by: :problem_resolved_by,
      }
      if SettingsHelper.has_review_period?
        hash
      else
        hash.except(:reviewed_at, :disputed_at, :dispute_reason, :dispute_resolved_at, :dispute_resolved_reason)
      end
    end

    def report_data_query
      Reports::Querier.new(
        order_status_id: order_status_ids,
        current_facility: facility,
        date_range_field: date_range_field,
        date_range_start: date_start,
        date_range_end: date_end,
        includes: [:reservation, :statement, :reservation, order: [:user]],
        preloads: [:created_by_user, :journal, order: [:facility], account: [:affiliate, :owner_user], price_policy: [:price_group]],
        transformer_options: { time_data: true, reporting: true },
      ).perform
    end

    def as_currency_difference(minuend, subtrahend)
      return "" unless minuend && subtrahend

      as_currency(minuend - subtrahend)
    end

    def as_currency(number)
      if number.present?
        ActionController::Base.helpers.number_to_currency(number)
      else
        ""
      end
    end

    def canceled_by_name(order_detail)
      if order_detail.canceled_by.try(:zero?)
        I18n.t("reports.fields.auto_cancel_name")
      else
        order_detail.canceled_by_user&.full_name(suspended_label: false)
      end
    end

  end

end
