# frozen_string_literal: true

class MinutesToTimeFormatter
  attr_reader :minutes

  def initialize(minutes)
    @minutes = minutes
  end

  def to_s
    "#{hours}:#{padded_minutes}"
  end

  private

  def hours
    (minutes / 60).floor
  end

  def padded_minutes
    (minutes % 60).to_s.rjust(2, "0")
  end
end
