# frozen_string_literal: true

module SecureRooms

  class CheckAccess

    DEFAULT_RULES = [
      AccessRules::RequiresUserRule,
      AccessRules::OperatorRule,
      AccessRules::ArchivedProductRule,
      AccessRules::RequiresApprovalRule,
      AccessRules::EgressRule,
      AccessRules::ScheduleRule,
      AccessRules::RequiresResearchSafetyCertificationsRule,
      AccessRules::AccountSelectionRule,
      AccessRules::DenyAllRule,
    ].freeze

    cattr_accessor(:rules) { DEFAULT_RULES.dup }

    def initialize(rules = self.class.rules)
      @rules = rules
    end

    def authorize(user, card_reader, params = {})
      answer = @rules.each do |rule|
        result = rule.new(user, card_reader, params).call
        break result unless result.pass?
      end
    end

  end

end
