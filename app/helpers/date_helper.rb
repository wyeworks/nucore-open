# frozen_string_literal: true

module DateHelper

  USA_DATE_FORMAT = %r(\A\d{1,2}/\d{1,2}/\d{4}\z)

  def usa_formatted_date?(date_string)
    date_string.present? && date_string =~ USA_DATE_FORMAT
  end

  def parse_usa_import_date(date_string)
    return nil unless usa_formatted_date?(date_string)
    begin
      parse_mmddyyyy_in_current_zone!(date_string)
    rescue ArgumentError
      nil
    end
  end

  # Expected date format: "MM/DD/YYYY"
  # Time string: "HH:MM AM/PM"
  def parse_usa_date(date, time_string = nil)
    date = date.to_s.strip

    # TODO: Many tests pass either a Date, a Time, or an YYYY-MM-DD formatted
    # string as a parameter. This conditional will handle those cases. We should
    # probably go through and clean up the tests at some point.
    date = format_usa_date(Date.parse(date)) if date =~ /\A\d{4}-\d{2}-\d{2}/

    return unless usa_formatted_date?(date)

    date_string = Date.strptime(date, "%m/%d/%Y").to_s
    date_string += " #{time_string}" if time_string

    Time.zone.parse(date_string)
  rescue ArgumentError
    nil
  end

  def format_usa_date(datetime)
    format_usa_datetime(datetime.try(:to_date))
  end

  def format_usa_datetime(datetime)
    datetime.present? ? I18n.l(datetime, format: :usa) : ""
  end

  def human_date(date)
    date.strftime("%B %e, %Y")
  end

  def human_time(dt)
    return nil if dt.nil?
    begin
      dt.strftime("%l:%M %p").strip
    rescue
      ""
    end
  end

  def time_ceil(time, precision = 5.minutes)
    time = time.dup.change(sec: 0)
    Time.zone.at((time.to_f / precision).ceil * precision)
  end

  def time_floor(time, precision = 5.minutes)
    time = time.dup.change(sec: 0)
    Time.zone.at((time.to_f / precision).floor * precision)
  end

  def time_select_tag(field, default_time = Time.zone.now, html_options = {})
    output = ""
    output += select_tag("#{field}[hour]", options_for_select(hour_options, default_time.strftime("%I").to_i), html_options)
    output += select_tag("#{field}[minute]", options_for_select(minute_options, default_time.min), html_options)
    output += select_tag("#{field}[ampm]", options_for_select(%w(AM PM), default_time.strftime("%p")), html_options)
    output.html_safe
  end

  # This is to DRY up many of the legacy places where hour/min/meridian is used in forms
  def time_select(f, field, options_tag = {}, html_options = {})
    output =  f.select(:"#{field}_hour", (1..12).to_a, {}, html_options.merge("aria-label": f.object.class.human_attribute_name("#{field}_hour")))
    output.safe_concat f.select(:"#{field}_min", minute_options(options_tag[:minute_step]), {}, html_options.merge("aria-label": f.object.class.human_attribute_name("#{field}_min")))
    output.safe_concat f.select(:"#{field}_meridian", %w(AM PM), {}, html_options.merge("aria-label": f.object.class.human_attribute_name("#{field}_meridian")))
    content_tag :div, output, class: "time-select"
  end

  def time_select24(f, field, options = {})
    options.reverse_merge! hours: (0..23)
    output =  f.select(:"#{field}_hour", options[:hours].to_a)
    output += f.select(:"#{field}_min", minute_options(options[:minute_step]))
    content_tag :div, output, class: "time-select"
  end

  def join_time_select_values(values)
    "#{values['hour']}:#{values['minute']} #{values['ampm']}"
  end

  private

  def minute_options(step = nil)
    step ||= 5
    (0..59).step(step).map { |d| ["%02d" % d, d] }
  end

  def hour_options
    (1..12).map { |x| [x, x] }
  end

  def parse_mmddyyyy_in_current_zone!(date_string)
    DateTime.strptime(date_string, "%m/%d/%Y").to_date.beginning_of_day
  end

end
