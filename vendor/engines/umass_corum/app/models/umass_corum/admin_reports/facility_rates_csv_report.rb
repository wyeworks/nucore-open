# frozen_string_literal: true

require "csv"

module UmassCorum

  module AdminReports

    class FacilityRatesCsvReport
      include TextHelpers::Translation
      include DateHelper
      include ActionView::Helpers::NumberHelper

      def to_csv
        CSV.generate do |csv|
          csv << headers
          PricePolicy.current.joins(:price_group).joins(product: [:facility]).order('facilities.name asc, products.name asc, price_groups.display_order asc').each do |price_policy|
            csv << build_row(price_policy)
          end
        end
      end

      def filename
        "facility_rates_data.csv"
      end

      def description
        text(".subject")
      end

      def text_content
        text(".body")
      end

      def has_attachment?
        true
      end

      def translation_scope
        "views.umass_corum.admin_reports.facility_rates"
      end

      private

      def headers
        [
          text(".facility_name"),
          text(".instrument_name"),
          text(".instrument_active"),
          text(".note"),
          text(".start_date"),
          text(".expire_date"),
          text(".billing_mode"),
          text(".pricing_mode"),
          text(".unit_cost"),
          text(".unit_subsidy"),
          text(".usage_rate"),
          text(".minimum_cost"),
          text(".cancellation_cost"),
          text(".usage_subsidy"),
          text(".duration_step_1"),
          text(".duration_rate_1"),
          text(".duration_subsidy_1"),
          text(".duration_step_2"),
          text(".duration_rate_2"),
          text(".duration_subsidy_2"),
          text(".duration_step_3"),
          text(".duration_rate_3"),
          text(".duration_subsidy_3"),
          text(".usage_rate_daily"),
          text(".usage_subsidy_daily"),
          text(".charge_for"),
          text(".full_price_cancellation"),
          text(".price_group_name"),
          text(".price_group_type"),
          text(".price_group_facility"),
          text(".creator"),
          text(".created_at"),
          text(".updated_at"),
          text(".deleted_at"),
        ]
      end

      def build_row(price_policy)
        product = price_policy.product
        price_group = price_policy.price_group
        [
          product.facility,
          product.name,
          product_status(product),
          price_policy.note,
          format_usa_datetime(price_policy.start_date),
          format_usa_datetime(price_policy.expire_date),
          product.billing_mode,
          product.pricing_mode,
          number_to_currency(price_policy.unit_cost),
          number_to_currency(price_policy.unit_subsidy),
          number_to_currency(price_policy.usage_rate),
          number_to_currency(price_policy.minimum_cost),
          number_to_currency(price_policy.cancellation_cost),
          number_to_currency(price_policy.usage_subsidy),
          duration_rate_step_value(price_policy, :min_duration_hours, 0),
          number_to_currency(duration_rate_step_value(price_policy, :rate, 0)),
          number_to_currency(duration_rate_step_value(price_policy, :subsidy, 0)),
          duration_rate_step_value(price_policy, :min_duration_hours, 1),
          number_to_currency(duration_rate_step_value(price_policy, :rate, 1)),
          number_to_currency(duration_rate_step_value(price_policy, :subsidy, 1)),
          duration_rate_step_value(price_policy, :min_duration_hours, 2),
          number_to_currency(duration_rate_step_value(price_policy, :rate, 2)),
          number_to_currency(duration_rate_step_value(price_policy, :subsidy, 2)),
          number_to_currency(price_policy.usage_rate_daily),
          number_to_currency(price_policy.usage_subsidy_daily),
          price_policy.charge_for.titlecase,
          cancellation_charge(price_policy),
          price_group.name,
          price_group.type_string,
          price_group.facility,
          price_policy.created_by,
          format_usa_datetime(price_group.created_at),
          format_usa_datetime(price_group.updated_at),
          (format_usa_datetime(price_group.deleted_at) unless price_group.deleted_at.nil?),
        ]
      end

      def product_status(product)
        product.is_archived? ? "Inactive" : "Active"
      end

      def cancellation_charge(price_policy)
        price_policy.full_price_cancellation ? "Yes" : nil
      end

      def duration_rate_step_value(price_policy, field, step)
        return nil unless price_policy.product.duration_pricing_mode?
        return nil unless price_policy.duration_rates.count > step
        price_policy.duration_rates[step][field]
      end
    end
  end
end
