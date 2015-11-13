class ScheduleRule < ActiveRecord::Base
  belongs_to :instrument

  # oracle has a maximum table name length of 30, so we have to abbreviate it down
  has_and_belongs_to_many :product_access_groups, :join_table => 'product_access_schedule_rules'

  attr_accessor :unavailable # virtual attribute

  validates_presence_of :instrument_id
  validates_numericality_of :discount_percent, :greater_than_or_equal_to => 0, :less_than => 100
  validates_numericality_of :start_hour, :end_hour, :only_integer => true, :greater_than_or_equal_to => 0, :less_than_or_equal_to => 24
  validates_numericality_of :start_min,  :end_min, :only_integer => true, :greater_than_or_equal_to => 0, :less_than => 60

  validate :at_least_one_day_selected, :end_time_is_after_start_time, :end_time_is_valid, :no_overlap_with_existing_rules, :no_conflict_with_existing_reservation

  def self.available_to_user(user)
    where(:product_users => {:user_id => user.id}).
    joins(:instrument => :product_users).
    # instrument doesn't have any restrictions at all, or has one that matches the product_user
    where("(not EXISTS (SELECT * FROM product_access_schedule_rules WHERE product_access_schedule_rules.schedule_rule_id = schedule_rules.id)
     OR (exists (select * from product_access_schedule_rules
         where product_access_schedule_rules.product_access_group_id = product_users.product_access_group_id
         and product_access_schedule_rules.schedule_rule_id = schedule_rules.id)))")
  end

  def self.unavailable_for_date(instrument, day)
    rules = where(instrument_id: instrument.id)
    rules = unavailable(rules)
    rules = rules.select { |item| item.public_send(:"on_#{day.strftime("%a").downcase}?")}
    rules.each_with_object([]) do |rule, reservations|
      reservations << Reservation.new(
        product: instrument,
        reserve_start_at: day.change(hour: rule.start_hour, min: rule.start_min),
        reserve_end_at: day.change(hour: rule.end_hour, min: rule.end_min),
        blackout: true
        )
    end
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
    if end_hour == 24 and end_min.to_i != 0
      errors.add(:base, "End time is invalid")
    end
  end

  def no_overlap_with_existing_rules
    return if instrument.blank?
    rules = instrument.schedule_rules.reject {|r| r.id == id} # select all rules except self
    Date::ABBR_DAYNAMES.each do |day|
      # skip unless this rule occurs on this day
      next unless self.send("on_#{day.downcase}?")
      # check all existing rules for this day
      rules.select{ |r| r.send("on_#{day.downcase}?") }.each do |rule|
        next if self.start_time_int == rule.end_time_int or self.end_time_int == rule.start_time_int # start and end times may touch
        if self.start_time_int.between?(rule.start_time_int, rule.end_time_int) or
           self.end_time_int.between?(rule.start_time_int, rule.end_time_int) or
           (self.start_time_int < rule.start_time_int and self.end_time_int > rule.end_time_int)
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
      days << day if self.send("on_#{day.downcase}?")
    end
    days.join ', '
  end

  def start_time_int
    start_hour*100+start_min
  end

  # multiplying by 100 means 8:00 is 800 -- it's time on a clock face minus the formatting and meridian

  def end_time_int
    end_hour*100+end_min
  end

  # Compare the start time of this with another schedule rule's
  def cmp_start(other)
    self.start_time_int <=> other.start_time_int
  end

  # Compare the end time of this with another schedule rule's
  def cmp_end(other)
    self.end_time_int <=> other.end_time_int
  end

  def start_time
    "#{start_hour}:#{sprintf '%02d', start_min}"
  end

  def end_time
    "#{end_hour}:#{sprintf '%02d', end_min}"
  end

  def includes_datetime(dt)
    dt_int = dt.hour * 100 + dt.min
    self.send("on_#{dt.strftime("%a").downcase}?") && dt_int >= start_time_int && dt_int <= end_time_int
  end

  # build weekly calendar object
  def as_calendar_object(options={})
    start_date = options[:start_date].presence || self.class.sunday_last
    num_days = options[:num_days] ? options[:num_days].to_i : 7
    title = ''

    if instrument && !unavailable
      duration_mins = instrument.reserve_interval
      title = "Interval: #{duration_mins} minute#{duration_mins == 1 ? '' : 's'}"
    end

    Range.new(0, num_days-1).inject([]) do |array, i|
      date = (start_date + i.days).to_datetime
      start_at = date.change hour: start_hour, min: start_min
      end_at = date.change hour: end_hour, min: end_min

      # check if rule occurs on this day
      if self.send("on_#{Date::ABBR_DAYNAMES[date.wday].downcase}?")
        array << {
          "className" => unavailable ? 'unavailable' : 'default',
          "title"  => title,
          "start"  => I18n.l(start_at, format: :calendar),
          "end"    => I18n.l(end_at, format: :calendar),
          "allDay" => false
        }
      end

      array
    end
  end

  def discount_for(start_at, end_at)
    percent_overlap(start_at, end_at) * discount_percent.to_f
  end

  def percent_overlap (start_at, end_at)
    return 0 unless end_at > start_at
    overlap  = 0
    duration = (end_at - start_at)/60
    # TODO rewrite to be more efficient; don't iterate over every minute
    while (start_at < end_at)
      if start_at.hour*100+start_at.min >= start_time_int && start_at.hour*100+start_at.min < end_time_int && self.send("on_#{start_at.strftime("%a").downcase}?")
        overlap += 1
      end
      start_at += 60
    end
    overlap / duration
  end

  def self.unavailable(rules)
    # rules is always a collection
    rules     = Array(rules)
    not_rules = []

    # group rules by day, sort by start_hour
    Date::ABBR_DAYNAMES.each do |day|
      day_rules = rules.select{ |rule| rule.send("on_#{day.downcase}?") }.sort_by{ |rule| rule.start_hour }

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

      unless not_start_hour == 24 && not_start_min == 0
        # build not rule for last part of day
        not_rule = ScheduleRule.new("on_#{day.downcase}" => true, :unavailable => true)
        not_rule.start_hour = not_start_hour
        not_rule.start_min  = not_start_min
        not_rule.end_hour   = 24
        not_rule.end_min    = 0
        not_rule.freeze
        not_rules.push(not_rule)
      end
    end

    not_rules
  end

  def self.sunday_last
    today = Time.zone.now
    (today - today.wday.days).to_date
  end

  # If we're at, say, 4:00, return 3. If we're at 4:01, return 4.
  def hour_floor
    end_min == 0 ? end_hour - 1 : end_hour
  end
end
