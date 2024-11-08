# frozen_string_literal: true

class CalendarEventsPresenter
  attr_reader :instrument,
              :reservations,
              :schedule_rules,
              :start_at,
              :end_at,
              :params

  def initialize(instrument, reservations, schedule_rules, start_at:, end_at:, **params)
    @instrument = instrument
    @reservations = reservations
    @schedule_rules = schedule_rules
    @start_at = start_at
    @end_at = end_at
    @params = params
  end

  def to_json(_opts = {})
    events
  end

  def events
    events ||= reservation_events + unavailable_events
  end

  private

  def unavailable_events
    inverse_rules = ScheduleRule.unavailable(schedule_rules)
    unavailable_calendar_opts = calendar_opts.merge(
      use_dates: monthly_view?
    )

    events = ScheduleRule.as_calendar_objects(
      inverse_rules,
      unavailable_calendar_opts
    )

    if monthly_view?
      events.each do |event|
        event.merge!("allDay" => true, "rendering" => "background")
      end
    end

    events
  end

  def reservation_events
    reservations.map do |reservation|
      reservation.as_calendar_object(calendar_opts)
    end
  end

  def calendar_opts
    {
      start_at:,
      end_at:,
      with_details: params[:with_details],
    }
  end

  def monthly_view?
    params[:view] == "month"
  end
end
