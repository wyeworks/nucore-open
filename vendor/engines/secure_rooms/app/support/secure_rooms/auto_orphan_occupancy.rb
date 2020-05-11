# frozen_string_literal: true

module SecureRooms

  class AutoOrphanOccupancy

    def perform
      long_running_occupancies.each do |occupancy|
        occupancy.transaction do
          orphan_occupancy(occupancy)
        end
      end
    end

    private

    def earliest_allowed_time
      Settings.occupancies.timeout_period.seconds.ago
    end

    def long_running_occupancies
      SecureRooms::Occupancy.current.where("entry_at < ?", earliest_allowed_time)
    end

    def orphan_occupancy(occupancy)
      occupancy.mark_orphaned!
      SecureRooms::AccessHandlers::OrderHandler.process(occupancy)
      MoveToProblemQueue.move!(occupancy.order_detail, cause: :auto_orphan) if occupancy.order_detail
    rescue => e
      ActiveSupport::Notifications.instrument("background_error",
                                              exception: e, information: "Failed orphan occupancy #{occupancy.id}")
      raise ActiveRecord::Rollback
    end

  end

end
