module SecureRooms

  class CheckAccess

    DEFAULT_RULES = [
      AccessRules::EgressRule,
      AccessRules::OperatorRule,
      AccessRules::ArchivedProductRule,
      AccessRules::RequiresApprovalRule,
      AccessRules::ScheduleRule,
      AccessRules::AccountSelectionRule,
      AccessRules::DenyAllRule,
    ].freeze

    def initialize(rules = DEFAULT_RULES)
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
