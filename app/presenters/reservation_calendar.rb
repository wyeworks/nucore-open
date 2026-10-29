# frozen_string_literal: true

class ReservationCalendar < SimpleDelegator
  attr_accessor :url, :ical

  def initialize(reservation, url: nil)
    super(reservation)
    @url = url
    generate_ical
  end

  def generate_ical
    @ical = Icalendar::Calendar.new
    ical.event do |e|
      e.dtstart = Icalendar::Values::DateTime.new(reserve_start_at)
      e.dtend = Icalendar::Values::DateTime.new(reserve_end_at)
      e.summary = summary
      e.description = description
      e.location = facility.name
      e.url = Icalendar::Values::Uri.new(url) if url.present?
      e.ip_class = "PRIVATE"
    end
    ical
  end

  def to_ical
    ical.publish
    ical.to_ical
  end

  def summary
    I18n.t("ical.summary", facility: facility.abbreviation, product: product.name)
  end

  def description
    I18n.t(
      "ical.description",
      facility: facility.name,
      product: product.name,
      order_number: order_detail.order_number)
  end

  def filename
    "reservation_cal_#{order_detail.order_number}.ics"
  end
end
