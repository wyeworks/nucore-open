# frozen_string_literal: true

module BulkEmail
  class AbilityExtension
    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      return unless user.manager_of?(resource) || user.facility_senior_staff_of?(resource)

      ability.can(:send_bulk_emails, resource)
    end
  end
end
