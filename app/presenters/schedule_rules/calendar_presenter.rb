# frozen_string_literal: true

module ScheduleRules

  class CalendarPresenter
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

    def to_json(_opts = {})
      events
    end

    def events
      date_range.filter_map do |date|
        hash_for_date(date.beginning_of_day) if rule_occurs_on_date?(date)
      end
    end

    private

    def date_range
      start_at.to_date..end_at.to_date
    end

    def hash_for_date(date)
      start_at = date.change(hour: start_hour, min: start_min)
      end_at = date.change(hour: end_hour, min: end_min)

      {
        "className" => class_name,
        "title" => title.to_s,
        "start" => format_date(start_at),
        "end" => format_date(end_at),
        "allDay" => false,
      }
    end

    def class_name
      @class_name ||= unavailable ? "unavailable" : "default"
    end

    def rule_occurs_on_date?(date)
      schedule_rule.public_send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}?")
    end

    # If start_at is not given, default to the beginning of the current week's Sunday
    def start_at
      @start_at ||= options[:start_at]&.beginning_of_day || Time.current.beginning_of_week(:sunday)
    end

    def end_at
      @end_at ||= (options[:end_at] || (start_at + 6.days)).end_of_day
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

    def format_date(timestamp)
      timestamp = timestamp.to_date if options[:use_dates]

      timestamp.iso8601
    end
  end

end
