# frozen_string_literal: true

class LogEvent < ApplicationRecord

  belongs_to :user # This is whodunnit
  belongs_to :loggable, -> { with_deleted if respond_to?(:with_deleted) }, polymorphic: true

  scope :reverse_chronological, -> { order(event_time: :desc) }

  def self.log(loggable, event_type, user, event_time: Time.current)
    create(
      loggable: loggable, event_type: event_type,
      event_time: event_time, user_id: user.try(:id))
  end

  def self.search(start_date: nil, end_date: nil, events: [], query: nil)
    LogEventSearcher.new(
      start_date: start_date, end_date: end_date, events: events, query: query).search
  end

  def locale_tag
    "#{loggable_type.underscore.downcase}.#{event_type}"
  end

  def loggable_to_s
    case loggable
    when AccountUser
      "#{loggable.account} / #{loggable.user}"
    when UserRole
      [
        loggable.user,
        "-",
        loggable.facility_id ? loggable.facility.abbreviation : "Global",
        loggable.role,
      ].join(" ")
    else
      loggable.to_s
    end
  end

end
