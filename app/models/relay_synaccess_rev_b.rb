# frozen_string_literal: true

class RelaySynaccessRevB < Relay
  # Supports Synaccess Models: NP-02B

  include PowerRelay

  private

  def self.to_s
    "Synaccess Revision B"
  end

  def relay_connection
    @relay_connection ||= NetBooter::Http::RevB.new(host, connection_options)
  end
end
