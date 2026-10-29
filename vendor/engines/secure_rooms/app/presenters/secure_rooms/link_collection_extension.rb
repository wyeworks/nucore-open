# frozen_string_literal: true

module SecureRooms
  module LinkCollectionExtension
    extend ActiveSupport::Concern

    included do
      insert_index = tab_methods.index(:admin_billing) || -1
      tab_methods.insert(insert_index, :admin_occupancies)
    end

    def admin_occupancies
      return unless single_facility? && SecureRoom.for_facility(facility).exists?

      NavTab::Link.new(
        tab: :admin_occupancies,
        url: dashboard_facility_occupancies_path(facility),
      )
    end
  end
end
