# frozen_string_literal: true

class ScheduleRuleCalendarPresenter

  include ActionView::Helpers::NumberHelper

  attr_reader :schedule_rule, :options

  delegate :end_hour, :end_min, :instrument, :start_hour, :start_min, :unavailable, to: :schedule_rule

  # Returns a single array of Hashes
  def self.to_json(schedule_rules, options = {})
    Array(schedule_rules).flat_map do |schedule_rule|
      new(schedule_rule, options).to_json
    end
  end

  def initialize(schedule_rule, options = {})
    @schedule_rule = schedule_rule
    @options = options
  end

  # Returns an array of hashes. A Mon-Fri 9-5 rule would return 5 hashes, one for
  # each day.
  def to_json
    Range.new(0, 6).map do |day_index|
      date = (start_date + day_index.days).to_datetime
      hash_for_date(date) if rule_occurs_on_date?(date)
    end.compact
  end

  private

  def hash_for_date(date)
    start_at = date.change(hour: start_hour, min: start_min)
    end_at = date.change(hour: end_hour, min: end_min)

    {
      "className" => class_name,
      "title" => title.to_s,
      "start" => start_at.iso8601,
      "end" => end_at.iso8601,
      "allDay" => false,
    }
  end

  def class_name
    @class_name ||= unavailable ? "unavailable" : "default"
  end

  def rule_occurs_on_date?(date)
    schedule_rule.public_send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}?")
  end

  # If start_date is not given, default to the beginning of the current week's Sunday
  def start_date
    options[:start_date].presence&.beginning_of_day || Time.current.beginning_of_week(:sunday)
  end

  def title
    [discount_percents, product_access_groups].compact.join("\n")
  end

  def discount_percents
    schedule_rule.price_group_discounts.map do |pgd|
      if pgd.discount_percent.to_i > 0
        number = number_to_percentage(pgd.discount_percent, strip_insignificant_zeros: true)
        "#{pgd.price_group.name}: #{number}"
      end
    end
  end

  def product_access_groups
    if schedule_rule.product_access_groups.any?
      schedule_rule.product_access_groups.join(", ")
    end
  end

end
