# frozen_string_literal: true

class LogEvent < ApplicationRecord
  belongs_to :user # This is whodunnit
  belongs_to :loggable, -> { with_deleted if respond_to?(:with_deleted) }, polymorphic: true
  has_one :archived_email, dependent: :destroy
  serialize :metadata, JSON

  BILLING_EVENT_TYPES = %w[
    user.review_orders_email
    statement.statement_email
    statement.closed
    journal.closed
  ].freeze

  scope :reverse_chronological, -> { order(event_time: :desc) }
  scope :with_billing_type, -> { with_events(BILLING_EVENT_TYPES) }
  scope :non_billing_type, -> { with_events(BILLING_EVENT_TYPES).invert_where }

  def self.log(loggable, event_type, user, event_time: Time.current, metadata: nil)
    create(
      loggable:,
      event_type:,
      event_time:,
      metadata:,
      user_id: user.try(:id),
    )
  end

  def self.log_email(loggable, event_type, email, metadata: {})
    create(
      loggable:,
      event_type:,
      event_time: Time.current,
      metadata: {
        to: email.to,
        subject: email.subject,
        **metadata
      }
    )
  end

  def self.with_events(events)
    events
      .map { |event| event.rpartition('.') }
      .map { |type, _, event_type| { loggable_type: type&.camelize, event_type: } }
      .map(&:compact_blank)
      .map { |cond| where(cond) }
      .inject(:or)
  end

  # The reason that we are doing this is because in some case we can't add a default value to a text column
  def metadata
    self[:metadata] || {}
  end

  def facility
    loggable.facility if loggable.respond_to?(:facility)
  end

  def locale_tag
    "log_event/event_type.#{loggable_type.underscore.downcase}.#{event_type}"
  end

  def loggable_to_s
    if loggable.respond_to?(:to_log_s)
      loggable.to_log_s
    else
      loggable.to_s
    end
  end

end
