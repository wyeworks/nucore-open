# frozen_string_literal: true

class RelayDummy < Relay

  def get_status
    return @active unless @active.nil?
    instrument.instrument_status&.is_on?
  end

  def activate
    @active = true
  end

  def deactivate
    @active = false
  end

  def control_mechanism
    CONTROL_MECHANISMS[:timer]
  end

end
