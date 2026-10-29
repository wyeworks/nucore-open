# frozen_string_literal: true

module TimeTravelHelpers
  def travel(duration, safe: false, &)
    warn "Use of Rails's #travel is unsafe in NUcore due to the global time-lock. Use `travel_and_return` instead #{caller(1..1)}" unless safe
    # Based on Rail's implementation. Calling `super` here would end up calling
    # our `travel_to`, which triggers the warning
    travel_to(Time.now + duration, safe: true, &)
  end

  def travel_to(date_or_time, safe: false)
    # See rails_helper
    warn "Use of Rails's #travel_to is unsafe in NUcore due to the global time-lock. Use `travel_to_and_return` instead #{caller(1..1)}" unless safe
    super(date_or_time)
  end

  def travel_and_return(interval)
    current_time = Time.current
    travel(interval, safe: true)
    yield
    travel_to(current_time, safe: true)
  end

  def travel_to_and_return(date_or_time)
    current_time = Time.current
    travel_to(date_or_time, safe: true)
    yield
    travel_to(current_time, safe: true)
  end
end
