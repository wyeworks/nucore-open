# frozen_string_literal: true

module SplitAccounts
  class AbilityExtension
    attr_reader :ability

    def initialize(ability)
      @ability = ability
    end

    def extend(user, _resource)
      ability.cannot :create, SplitAccounts::SplitAccount unless can_create_split_account?(user)
    end

    private

    def can_create_split_account?(user)
      user.user_roles.any? { |role| role.in?(valid_roles) }
    end

    def valid_roles
      Settings.split_accounts.create_roles
    end
  end
end
