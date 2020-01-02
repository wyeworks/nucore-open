# frozen_string_literal: true

module NuResearchSafety

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, resource)
      if user.operator_of?(resource)
        ability.can([:index, :create, :destroy], NuResearchSafety::ProductCertificationRequirement)
      end
    end

  end

end
