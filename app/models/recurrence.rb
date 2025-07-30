# frozen_string_literal: true

# Recurrence.new(30.days.ago, 30.days.ago + 1.hour).weekdays.take(10).map { |t| [t.start_time, t.end_time] }
# Recurrence.new(30.days.ago, 30.days.ago + 1.hour, until_time: 10.days.ago).weekdays.map { |t| [t.start_time, t.end_time] }
class Recurrence

  include Enumerable

  delegate :each, to: :to_enum

  def initialize(start_at, end_at, until_time: nil)
    @until_time = until_time
    @schedule = IceCube::Schedule.new(
      start_at, end_time: end_at)
  end

  def daily
    @schedule.add_recurrence_rule IceCube::Rule.daily.until(@until_time)
    self
  end

  def weekdays
    @schedule.add_recurrence_rule IceCube::Rule.weekly.day(:monday, :tuesday, :wednesday, :thursday, :friday).until(@until_time)
    self
  end

  def weekly
    @schedule.add_recurrence_rule IceCube::Rule.weekly.until(@until_time)
    self
  end

  def monthly
    @schedule.add_recurrence_rule IceCube::Rule.monthly.until(@until_time)
    self
  end

  def to_enum
    @schedule.all_occurrences_enumerator
  end

end
