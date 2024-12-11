# frozen_string_literal: true

module UmassCorum

  class AbilityExtension

    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, _resource)
      unless user.administrator?
        ability.cannot([:create, :edit, :update], UmassCorum::SubsidyAccount)
      end
    end
  end

end
