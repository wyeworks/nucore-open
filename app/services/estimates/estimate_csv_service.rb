# frozen_string_literal: true

module Estimates
  class EstimateCsvService
    include DateHelper

    def initialize(estimate)
      @estimate = estimate
    end

    def to_csv
      CSV.generate do |csv|
        csv << ["Estimate Information"]
        csv << ["ID", "Description", "Created By", "Username", "Expiration Date"]
        csv << [@estimate.id, @estimate.description, @estimate.created_by_user.full_name, @estimate.user_display_name, format_usa_date(@estimate.expires_at)]
        csv << []

        if @estimate.note.present?
          csv << ["Notes"]
          csv << [@estimate.note.strip]
          csv << []
        end

        csv << ["Products"]
        csv << ["Facility", "Product", "Quantity", "Duration", "Unit Price", "Price"]

        @estimate.estimate_details.includes(:product).each do |estimate_detail|
          unit_price = estimate_detail.price_policy&.unit_net_cost

          csv << [
            estimate_detail.product.facility.name,
            estimate_detail.product.name,
            estimate_detail.quantity,
            format_duration(estimate_detail),
            unit_price.presence && helpers.number_to_currency(unit_price),
            helpers.number_to_currency(estimate_detail.cost)
          ]
        end

        csv << []
        csv << ["Total", "", "", "", "", helpers.number_to_currency(@estimate.total_cost)]
      end
    end

    private

    def helpers
      ActionController::Base.helpers
    end

    def format_duration(estimate_detail)
      if estimate_detail.duration_unit == "mins"
        MinutesToTimeFormatter.new(estimate_detail.duration).to_s
      elsif estimate_detail.duration_unit.present?
        "#{estimate_detail.duration} days"
      end
    end
  end
end
