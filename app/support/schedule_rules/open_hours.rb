# frozen_string_literal: true

module ScheduleRules

  class OpenHours
    attr_reader :schedule_rules

    def initialize(schedule_rules)
      @schedule_rules = schedule_rules
    end

    def self.weekdays
      Date::ABBR_DAYNAMES
    end

    def self.time_range(start_time, end_time)
      [start_time, end_time].join(" - ")
    end

    # Build a Hash[String, String] with weekdays as keys
    # and availabile time as values by grouping schedule rules
    # availability
    def per_weekday
      entries = rules_times.group_by { |entry| entry[:weekday] }

      self.class.weekdays.index_with do |weekday|
        entries[weekday]&.pluck(:range)&.join(", ")
      end
    end

    private

    def rules_times
      return @rules_times if @rules_times.present?

      @rules_times =
        self.class.weekdays.flat_map do |weekday|
          wday_rules = schedule_rules.filter { |sr| sr.on_day?(weekday) }

          merged_rule_times(wday_rules).map do |time|
            { weekday:, range: self.class.time_range(time[:start], time[:end]) }
          end
        end
    end

    # Return an Array[{start:, end:}] containing an entry for
    # each rule but merging those rules that have continuous times
    def merged_rule_times(rules)
      rules.sort_by(&:start_time_int).reduce([[], 0]) do |ac, rule|
        entries, current_time = ac

        if rule.start_time_int == current_time
          entry = entries.last || { start: rule.start_time }
          entry[:end] = rule.end_time
          entries << entry if entries.empty?
        else
          entries << { start: rule.start_time, end: rule.end_time }
        end

        [entries, rule.end_time_int]
      end.first
    end
  end

end
