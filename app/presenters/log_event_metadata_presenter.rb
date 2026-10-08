# frozen_string_literal: true

class LogEventMetadataPresenter

  SUPPORTED_EVENT = "statement.unreconciled"

  def initialize(log_event)
    @log_event = log_event
  end

  def details
    return [] unless event_tag == SUPPORTED_EVENT

    {
      deposit_number: values("deposit_numbers").join(", "),
      reconciled_note: values("reconciled_notes").join("; "),
    }.compact_blank.map { |attribute, value| [OrderDetail.human_attribute_name(attribute), value] }
  end

  def to_s
    details.map { |label, value| "#{label}: #{value}" }.join(" ")
  end

  private

  attr_reader :log_event

  def event_tag
    "#{log_event.loggable_type.underscore}.#{log_event.event_type}"
  end

  def values(key)
    Array(log_event.metadata[key])
  end

end
