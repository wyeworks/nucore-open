# frozen_string_literal: true

class RelayDataprobe < Relay
  include PowerRelay

  private

  def self.to_s
    "Dataprobe iPIO"
  end

  def relay_connection
    @relay_connection ||= Dataprobe::Ipio.new(host, connection_options)
  end
end
