# frozen_string_literal: true

require "net/http"

class Relay < ApplicationRecord

  belongs_to :instrument, inverse_of: :relay

  validates_presence_of :instrument_id, on: :update
  validate :unique_ip

  alias_attribute :host, :ip

  CONTROL_MECHANISMS = {
    manual: nil,
    timer: "timer",
    relay: "relay",
  }.freeze

  def get_status
    query_status
  end

  def activate
    toggle(true)
  end

  def deactivate
    toggle(false)
  end

  def control_mechanism
    CONTROL_MECHANISMS[:manual]
  end

  def networked_relay?
    control_mechanism == CONTROL_MECHANISMS[:relay]
  end

  private

  def toggle(_status)
    raise NotImplementedError.new("Subclass must define")
  end

  def query_status
    raise NotImplementedError.new("Subclass must define")
  end

  def unique_ip
    return unless ip.present?
    scope = Relay.unscoped.where(ip: ip, outlet: outlet, ip_port: ip_port)
    scope = scope.joins(:instrument).where("products.schedule_id != ?", instrument.schedule_id) if instrument.try(:schedule_id)
    scope = scope.where("relays.id != ?", id) if persisted?
    errors.add :outlet, :taken if scope.exists?
  end

end
