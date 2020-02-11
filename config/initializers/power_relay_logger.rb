# frozen_string_literal: true

class PowerRelayLogger < ActiveSupport::LogSubscriber

  def status(event)
    render event, "Got status with options #{event.payload[:options]}. Status: #{event.payload[:status]}"
  end

  def toggle(event)
    render event, "Toggled status with options #{event.payload[:options]}. Status: #{event.payload[:result]}"
  end

  private

  def render(event, message, display_color: GREEN)
    return unless logger.debug?

    debug color("[PowerRelays] (#{event.duration.round(1)}ms) #{message}", display_color, true)
  end

end

PowerRelayLogger.attach_to :power_relays
