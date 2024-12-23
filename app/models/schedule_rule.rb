# frozen_string_literal: true

class ScheduleRule < ApplicationRecord
  belongs_to :product

  # oracle has a maximum table name length of 30, so we have to abbreviate it down
  has_and_belongs_to_many :product_access_groups, join_table: "product_access_schedule_rules"
  has_many :price_group_discounts, dependent: :destroy

  accepts_nested_attributes_for :price_group_discounts

  attr_accessor :unavailable # virtual attribute

  validates_presence_of :product_id
  validates_numericality_of :start_hour, :end_hour, only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 24
  validates_numericality_of :start_min,  :end_min, only_integer: true, greater_than_or_equal_to: 0, less_than: 60

  validate :at_least_one_day_selected, :end_time_is_after_start_time, :end_time_is_valid, :no_overlap_with_existing_rules, :no_conflict_with_existing_reservation

  def self.available_to_user(user)
    where(product_users: { user_id: user.id })
      .joins(product: :product_users).
      # product doesn't have any restrictions at all, or has one that matches the product_user
      where("(not EXISTS (SELECT * FROM product_access_schedule_rules WHERE product_access_schedule_rules.schedule_rule_id = schedule_rules.id)
     OR (exists (select * from product_access_schedule_rules
         where product_access_schedule_rules.product_access_group_id = product_users.product_access_group_id
         and product_access_schedule_rules.schedule_rule_id = schedule_rules.id)))")
  end

  # Use this on an ActiveRecord::Relation. Is every minute within the range covered
  # by one of the rules?
  def self.cover?(start_at, end_at = start_at)
    # Time Ranges aren't iterable, so fake it by creating an array of each minute
    # beween the two times. If start_at == end_at, the result will be one element.
    minutes = (end_at - start_at) / 60
    each_minute_in_range = 0.upto(minutes).collect { |n| start_at.advance(minutes: n) }

    each_minute_in_range.all? do |time|
      cover_time?(time)
    end
  end

  def self.cover_time?(time)
    any? { |rule| rule.cover?(time) }
  end

  # Returns a single array of calendar objects representing the set of schedule_rules
  def self.as_calendar_objects(schedule_rules, options = {})
    ScheduleRules::CalendarPresenter.events(schedule_rules, options).as_json
  end

  def self.full_day_attributes
    {
      start_hour: 0, start_min: 0,
      end_hour: 0, end_min: 1
    }
  end

  def at_least_one_day_selected
    errors.add(:base, "Please select at least one day") unless
      on_sun? || on_mon? || on_tue? || on_wed? || on_thu? || on_fri? || on_sat?
  end

  def end_time_is_after_start_time
    return if start_hour.nil? || end_hour.nil? || start_min.nil? || end_min.nil?
    errors.add(:base, "End time must be after start time") if (end_hour < start_hour) || (end_hour == start_hour && end_min <= start_min)
  end

  def end_time_is_valid
    if end_hour == 24 && end_min.to_i != 0
      errors.add(:base, "End time is invalid")
    end
  end

  def no_overlap_with_existing_rules
    return if product.blank?
    rules = product.schedule_rules.reject { |r| r.id == id } # select all rules except self
    Date::ABBR_DAYNAMES.each do |day|
      # skip unless this rule occurs on this day
      next unless send("on_#{day.downcase}?")
      # check all existing rules for this day
      rules.select { |r| r.send("on_#{day.downcase}?") }.each do |rule|
        next if start_time_int == rule.end_time_int || end_time_int == rule.start_time_int # start and end times may touch
        if start_time_int.between?(rule.start_time_int, rule.end_time_int) ||
           end_time_int.between?(rule.start_time_int, rule.end_time_int) ||
           (start_time_int < rule.start_time_int && end_time_int > rule.end_time_int)
          # overlap
          errors.add(:base, "This rule conflicts with an existing rule on #{day}")
        end
      end
    end
  end

  def no_conflict_with_existing_reservation
    # TODO: implement me
    true
  end

  def days_string
    days = []
    Date::ABBR_DAYNAMES.each do |day|
      days << day if send("on_#{day.downcase}?")
    end
    days.join ", "
  end

  def start_time_int
    start_hour * 100 + start_min
  end

  # multiplying by 100 means 8:00 is 800 -- it's time on a clock face minus the formatting and meridian

  def end_time_int
    end_hour * 100 + end_min
  end

  def start_time
    "#{start_hour}:#{sprintf '%02d', start_min}"
  end

  def end_time
    "#{end_hour}:#{sprintf '%02d', end_min}"
  end

  def time_range
    [start_time, end_time].join(" - ")
  end

  def on_day?(value)
    weekday = case value
              when Integer then Date::ABBR_DAYNAMES[value]
              when String then value
              when Time then value.strftime("%a")
              end

    Date::ABBR_DAYNAMES.include?(weekday) && public_send(:"on_#{weekday.downcase}?")
  end

  def cover?(dt)
    return false unless on_day?(dt)

    dt_int = dt.hour * 100 + dt.min
    dt_int >= start_time_int && dt_int <= end_time_int
  end

  # Build weekly calendar hashes
  # Returns an array of hashes. A Mon-Fri 9-5 rule would return 5 hashes, one for
  # each day.
  def as_calendar_objects(options = {})
    ScheduleRules::CalendarPresenter.new(self, options).as_json
  end

  def discount_for(start_at, end_at, price_group)
    percent_overlap(start_at, end_at) * discount_for_price_group(price_group)
  end

  def discount_for_price_group(price_group)
    pgd = price_group_discounts.where(
      price_group: effective_price_group(price_group)
    ).first

    # TODO: This should always be defined, remove once price_group_discounts have been
    # added to all existing schedule rules and this is no longer needed.
    if pgd
      pgd.discount_percent.to_f
    else
      Rollbar.warn("Schedule rule missing price group discount", schedule_rule: id) if defined? Rollbar
      0
    end
  end

  def effective_price_group(price_group)
    if price_group.global?
      price_group
    elsif price_group.is_internal?
      PriceGroup.base
    else
      PriceGroup.external
    end
  end

  # Inverts a set of rules into another set of rules representing the times the
  # product is unavailable.
  #
  # Example:
  # Input: A set of rules representing every day, available from 9-noon and 1-5.
  # Output: A set of rules for each day, midnight-9, noon-1, and 5-midnight
  def self.unavailable(rules)
    # rules is always a collection
    rules     = Array(rules)
    not_rules = []

    # group rules by day, sort by start_hour
    Date::ABBR_DAYNAMES.each do |day|
      day_rules = rules.select { |rule| rule.send("on_#{day.downcase}?") }.sort_by(&:start_hour)

      if day_rules.empty?
        # build entire day not rule
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :start_hour => 0, :start_min => 0, :end_hour => 24, :end_min => 0,
                                    :unavailable => true)
        not_rule.freeze
        not_rules.push(not_rule)
        next
      end

      # build not available rules as contiguous blocks between existing rules
      not_start_hour = 0
      not_start_min  = 0

      day_rules.each do |day_rule|
        if day_rule.start_hour == not_start_hour && day_rule.start_min == not_start_min
          # adjust not times, but don't build a not rule
          not_start_hour  = day_rule.end_hour
          not_start_min   = day_rule.end_min
          next
        end
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :unavailable => true)
        not_rule.start_hour = not_start_hour
        not_rule.start_min  = not_start_min
        not_rule.end_hour   = day_rule.start_hour
        not_rule.end_min    = day_rule.start_min
        not_start_hour      = day_rule.end_hour
        not_start_min       = day_rule.end_min
        not_rule.freeze
        not_rules.push(not_rule)
      end

      next if not_start_hour == 24 && not_start_min == 0
      # build not rule for last part of day
      not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :unavailable => true)
      not_rule.start_hour = not_start_hour
      not_rule.start_min  = not_start_min
      not_rule.end_hour   = 24
      not_rule.end_min    = 0
      not_rule.freeze
      not_rules.push(not_rule)
    end

    not_rules
  end

  # If we're at, say, 4:00, return 3. If we're at 4:01, return 4.
  def hour_floor
    end_min == 0 ? end_hour - 1 : end_hour
  end

  private

  def percent_overlap(start_at, end_at)
    # Strip off seconds
    start_at = start_at.change(sec: 0)
    end_at = end_at.change(sec: 0)

    return 0 unless end_at > start_at
    total_mins = TimeRange.new(start_at, end_at).duration_mins

    minutes_overlap(start_at, end_at).fdiv total_mins
  end

  def minutes_overlap(start_at, end_at)
    overlap_mins = 0
    # TODO: rewrite to be more efficient; don't iterate over every minute
    while start_at < end_at
      if start_at.hour * 100 + start_at.min >= start_time_int && start_at.hour * 100 + start_at.min < end_time_int && on_day?(start_at)
        overlap_mins += 1
      end
      start_at += 60
    end
    overlap_mins
  end

end
