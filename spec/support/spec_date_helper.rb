# Including `DateHelper` at the wrong spot in specs can cause hard to debug
# problems. So, where possible, this class should be instead.
class SpecDateHelper
  include DateHelper

  def self.format_usa_date(datetime)
    new.format_usa_date(datetime)
  end

  def self.format_usa_datetime(datetime)
    new.format_usa_datetime(datetime)
  end

  def self.parse_usa_date(date, time_string = nil)
    new.parse_usa_date(date, time_string)
  end

  def self.human_date(date)
    new.human_date(date)
  end
end
