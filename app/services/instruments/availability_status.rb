# frozen_string_literal: true

module Instruments

  # Request-scoped instrument availability for the public facility page: two
  # facility-wide queries instead of running walkup_available? per instrument.
  # Build once, reuse for every instrument on the page.
  class AvailabilityStatus

    def initialize(facility)
      @facility = facility
    end

    # Open now per its schedule rules and its schedule not currently in use.
    def available_now?(product)
      return false if in_use_schedule_ids.include?(product.schedule_id)

      schedule_rules_by_product.fetch(product.id, []).any? { |rule| rule.cover?(Time.current) }
    end

    private

    # Keyed on schedule so shared-schedule instruments block each other, matching
    # conflicting_*_reservation's `product.schedule.product_ids`.
    def in_use_schedule_ids
      @in_use_schedule_ids ||=
        Reservation.current_in_use
                   .joins(:product)
                   .where(products: { facility_id: @facility.id })
                   .distinct
                   .pluck("products.schedule_id")
                   .to_set
    end

    def schedule_rules_by_product
      @schedule_rules_by_product ||=
        ScheduleRule.joins(:product)
                    .where(products: { facility_id: @facility.id })
                    .group_by(&:product_id)
    end

  end

end
