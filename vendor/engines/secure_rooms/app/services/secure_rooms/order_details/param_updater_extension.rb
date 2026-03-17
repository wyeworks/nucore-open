# frozen_string_literal: true

module SecureRooms

  module OrderDetails

    module ParamUpdaterExtension

      extend ActiveSupport::Concern

      included do
        permitted_attributes.append(
          occupancy_attributes: [
            {
              entry_at: [:date, :hour, :minute, :ampm],
              exit_at: [:date, :hour, :minute, :ampm]
            },
          ],
        )
      end

    end

  end

end
