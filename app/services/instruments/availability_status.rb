# frozen_string_literal: true

module Instruments

  # Request-scoped instrument availability for the public facility page: two
  # facility-wide queries instead of running walkup_available? per instrument.
  # Build once, reuse for every instrument on the page.
  class AvailabilityStatus

    def initialize(facility)
      @facility = facility
    end

    # Open now per its schedule rules, its schedule not currently in use, and not
    # a holiday it restricts access on.
    def available_now?(product)
      return false if in_use_schedule_ids.include?(product.schedule_id)
      return false if closed_for_holiday?(product)

      schedule_rules_by_product.fetch(product.id, []).any? { |rule| rule.cover?(Time.current) }
    end

    private

    # No user on the public page, so a holiday only closes instruments that
    # restrict access (nobody to override it).
    def closed_for_holiday?(product)
      product.restrict_holiday_access? && holiday_today?
    end

    def holiday_today?
      return @holiday_today unless @holiday_today.nil?

      @holiday_today = Holiday.on(Time.current.to_date).exists?
    end

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
