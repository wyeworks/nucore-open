# frozen_string_literal: true

class RelaySynaccessRevA < Relay
  # Supports Synaccess Models: NP-02

  include PowerRelay

  private

  def self.to_s
    "Synaccess Revision A"
  end

  def relay_connection
    @relay_connection ||= NetBooter::Http::RevA.new(host, connection_options)
  end
end
