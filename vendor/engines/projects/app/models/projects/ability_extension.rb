# frozen_string_literal: true

module Projects

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource) && !user.facility_billing_administrator_of?(resource)
        ability.can([:create, :edit, :inactive, :index, :new, :show, :update], Projects::Project)
      end

      if SettingsHelper.feature_on?(:cross_core_order_view) && resource.is_a?(Facility) && (user.facility_staff_or_manager_of?(resource) || user.facility_director_of?(resource))
        ability.can :cross_core_orders, Projects::Project
      end
    end

  end

end
