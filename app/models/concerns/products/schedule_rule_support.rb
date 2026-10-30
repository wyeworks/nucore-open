# frozen_string_literal: true

module Products::ScheduleRuleSupport
  extend ActiveSupport::Concern

  included do
    has_many :schedule_rules, foreign_key: :product_id, inverse_of: :product
    has_many :product_access_groups, foreign_key: :product_id, inverse_of: :product
  end

  def can_purchase?(group_ids = nil)
    return false if schedule_rules.empty?

    super
  end

  def first_available_hour
    return 0 unless schedule_rules.any?

    schedule_rules.min_by(&:start_hour).start_hour
  end

  def last_available_hour
    return 23 unless schedule_rules.any?

    max_rule = schedule_rules.max_by(&:hour_floor)
    max_rule.end_min.zero? ? max_rule.end_hour - 1 : max_rule.end_hour
  end

  def available_schedule_rules(user)
    if requires_approval? && user
      schedule_rules.available_to_user user
    else
      schedule_rules
    end
  end
end
