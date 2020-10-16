# frozen_string_literal: true

class TimeRange

  attr_reader :start_at, :end_at

  def initialize(start_at, end_at)
    @start_at = start_at
    @end_at = end_at
  end

  def to_s
    "#{start_string} - #{end_string}"
  end

  def duration_mins
    return unless start_at && end_at
    # For the sake of charging, NU asked for us to strip seconds from
    # calculations so that displayed time ranges and prices always lined up.
    # e.g. 4:17-4:18 should get priced at one minute, even if the actual time
    # was slightly longer than a minute: 4:17.5 and 4:18.7.
    minutes = ((end_at.change(sec: 0) - start_at.change(sec: 0)) / 60).to_i
    # After we've stripped the seconds, we should still charge at least one minute.
    # E.g. you start and end a reservation within 15 seconds.
    [minutes, 1].max
  end

  private

  def start_string
    localize(start_at)
  end

  def end_string
    if start_at && end_at && start_at.to_date == end_at.to_date
      localize(end_at, format: :timeonly)
    else
      localize(end_at)
    end
  end

  def localize(time, *options)
    time ? I18n.localize(time, *options) : "???"
  end

end
