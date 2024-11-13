# frozen_string_literal: true

module Products::SchedulingSupport

  extend ActiveSupport::Concern

  included do
    belongs_to :schedule, inverse_of: :products
    has_many :reservations, foreign_key: "product_id"

    before_save :create_default_schedule, unless: :schedule
    before_save :update_schedule_name, if: :name_changed?
  end

  def started_reservations
    reservations
      .purchased
      .not_canceled
      .merge(OrderDetail.unreconciled)
      .merge(Reservation.relay_in_progress)
  end

  def walkup_available?(time = Time.zone.now, interval: reserve_interval)
    # zero and nil should default to 1 minute
    reservation_length = [min_reserve_mins.to_i, interval.to_i].max
    reservation = Reservation.new(
      product: self,
      reserve_start_at: time,
      reserve_end_at: time + reservation_length.minutes,
      blackout: true # so it's not considered an admin and allowed to overlap
    )
    reservation.valid?(:walkup_available)
  end

  # find the next available reservation based on schedule rules and existing reservations
  def next_available_reservation(after: Time.zone.now, duration: 1.minute, options: {})
    rules = rules_for_day(after.wday, options[:user])
    # if the user has no schedule rules, there will be no time that they can
    # move the reservation to
    return nil unless rules.any?
    reservation_in_week(after, duration, rules, options)
  end

  # The next available reservation that is valid must be in the future
  # (see Reservations::Validations#in_the_future) so the `after` parameter is
  # set to 1 minute in the future so quick_reservation_data returns data that
  # can be used to create a valid reservation
  def quick_reservation_data(after: 1.minute.from_now)
    res = next_available_reservation(after:, duration: quick_reservation_intervals.first)

    quick_reservation_intervals.select { |i| walkup_available?(after, interval: i) }
                               .map { |i| { reserve_start_at: res.reserve_start_at, duration_mins: i } }
  end

  def quick_reservation_intervals
    intervals = case reserve_interval
                when 1, 5, 15
                  [15, 30, 60]
                when 10
                  [10, 30, 60]
                when 30
                  [30, 60, 90]
                when 60
                  [60, 120, 180]
                end

    max_time = max_reserve_mins.presence || 181
    min_time = min_reserve_mins.to_i

    intervals.select! do |i|
      min_time <= i && i <= max_time
    end

    intervals = [min_reserve_mins] if intervals.empty?

    intervals
  end

  def offline?
    current_offline_reservations.present?
  end

  def offline_category
    current_offline_reservation.try(:category)
  end

  def online!
    offline_reservations.current.update_all(reserve_end_at: Time.current)
  end

  def online?
    !offline?
  end

  private

  def current_offline_reservation
    offline_reservations.current.last
  end

  def reservation_in_week(after, duration, rules, options)
    day_of_week = after.wday

    0.upto(6) do |i|
      day_of_week = (day_of_week + i) % 6

      rules.each do |rule|
        finder = ReservationFinder.new(after, rule, options)
        reservation = finder.next_reservation(self, duration)
        return reservation if reservation
      end

      # advance to start of next day
      after = after.end_of_day + 1.second
      return nil if options[:until] && after >= options[:until]
    end

    # no availability found in this week; check next week
    reservation_in_week after, duration, rules, options
  end

  # find rules for day of week, sort by start hour
  def rules_for_day(day_of_week, user)
    rules = available_schedule_rules(user).select { |r| r.send("on_#{Date::ABBR_DAYNAMES[day_of_week].downcase}".to_sym) }
    rules.sort_by(&:start_hour)
  end

  def create_default_schedule
    self.schedule = Schedule.create(name: "#{name} Schedule", facility: facility)
  end

  def update_schedule_name
    if schedule.name == "#{name_was} Schedule"
      schedule.update(name: "#{name} Schedule")
    end
  end

  class ReservationFinder

    def initialize(time, rule, options = {})
      @time       = time
      @rule       = rule
      @options    = options
    end

    def next_reservation(reserver, duration)
      next_time = next_reserval_interval_start(earliest_possible_start(@time))
      non_conflicting_reservation(next_time, reserver, duration)
    end

    private

    def earliest_possible_start(time)
      if @options[:ignore_cutoff] || @rule.product.cutoff_hours <= 0
        # pick the later of provided time and @rule's start-of-day
        [time, day_start].max
      else
        # handle cutoff hours if needed
        [time, day_start, @rule.product.cutoff_hours.hours.from_now].max
      end
    end

    def next_reserval_interval_start(time)
      # ensure reservation start times abide by instrument's reserve_interval (i.e. 5 min increments)
      reserve_interval = @rule.product.reserve_interval.to_i
      if reserve_interval <= 0 || (time.min % reserve_interval).zero?
        time
      else
        time + (reserve_interval - time.min % reserve_interval).minutes
      end
    end

    def non_conflicting_reservation(time, reserver, duration)
      while time < day_end
        reservation = reserver.reservations.new(reserve_start_at: time, reserve_end_at: time + duration)

        conflict = reservation.conflicting_user_reservation(exclude: @options[:exclude])
        admin_conflict = reservation.conflicting_admin_reservation
        return reservation if [conflict, admin_conflict].none?

        time = [conflict, admin_conflict].compact.max_by(&:reserve_end_at).reserve_end_at
      end
    end

    def day_start
      Time.zone.local(@time.year, @time.month, @time.day, @rule.start_hour, @rule.start_min, 0)
    end

    def day_end
      Time.zone.local(@time.year, @time.month, @time.day, @rule.end_hour, @rule.end_min, 0)
    end

  end

end
