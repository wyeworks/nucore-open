# frozen_string_literal: true

module SecureRooms
  class AccessManager
    PROCESSING_CHAIN = [
      SecureRooms::AccessHandlers::EventHandler,
      SecureRooms::AccessHandlers::OccupancyHandler,
      SecureRooms::AccessHandlers::OrderHandler,
    ].freeze

    def self.process(verdict)
      PROCESSING_CHAIN.inject(verdict) do |result, handler|
        result = handler.process(result)
        result || break
      end
    end
  end
end
