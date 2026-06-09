# frozen_string_literal: true

module SecureRooms

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource)
        ability.can [
          :index,
          :dashboard,
          :tab_counts,
        ], Occupancy
      end

      if user.manager_of?(resource)
        ability.can [
          :assign_price_policies_to_problem_orders,
        ], Occupancy
      end

      if user.manager_of?(resource) || user.facility_senior_staff_of?(resource)
        ability.can :manage, CardReader
        ability.can :show_problems, Occupancy
      end

      if granted_read_access?(user, resource)
        ability.can [:index, :dashboard, :tab_counts, :show], Occupancy
        ability.can [:index, :show], CardReader
      end

      if granted_product_edition?(user, resource)
        ability.can :manage, CardReader
      end
    end

    private

    def granted_read_access?(user, resource)
      return false unless SettingsHelper.feature_on?(:granular_permissions)
      return false unless resource.is_a?(Facility)

      user.facility_user_permissions.find_by(facility: resource)&.read_access?
    end

    def granted_product_edition?(user, resource)
      return false unless SettingsHelper.feature_on?(:granular_permissions)
      return false unless resource.is_a?(Facility)

      user.facility_user_permissions.find_by(facility: resource)&.product_edition?
    end

  end

end
