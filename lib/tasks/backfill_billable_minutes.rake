# frozen_string_literal: true

desc "Backfills billable_minutes on existing Reservations"
task backfill_billable_minutes: :environment do
  Reservation
    .joins(order_detail: :price_policy)
    .where(order_details: { state: ["complete", "reconciled"], canceled_at: nil }, price_policies: { charge_for: "reservation" })
    .where(reservations: { billable_minutes: nil })
    .find_each { |reservation| reservation.update_billable_minutes }

  Reservation
    .joins(order_detail: :price_policy)
    .where(order_details: { state: ["complete", "reconciled"], canceled_at: nil }, price_policies: { charge_for: ["usage", "overage"] })
    .where(reservations: { billable_minutes: nil })
    .where.not(reservations: { actual_start_at: nil, actual_end_at: nil })
    .find_each { |reservation| reservation.update_billable_minutes }
end
