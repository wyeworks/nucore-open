# frozen_string_literal: true

module Products::RelaySupport

  extend ActiveSupport::Concern

  included do
    has_one :relay, inverse_of: :instrument, dependent: :destroy
    has_many :instrument_statuses, foreign_key: "instrument_id", inverse_of: :instrument

    accepts_nested_attributes_for :relay
  end

  # control mechanism for instrument
  def control_mechanism
    relay.try(:control_mechanism)
  end

  def current_instrument_status
    # With the unique index on instrument_id, there's only one status per instrument
    instrument_statuses.first
  end

  def has_real_relay?
    relay && !relay.is_a?(RelayDummy) && relay.ip? && relay.outlet?
  end

  # We only want to destroy the existing relay if the new one is valid.
  # See https://andycroll.com/ruby/be-careful-assigning-to-has-one-relations/
  def replace_relay(attributes = nil, param_control_mechanism = nil)
    self.class.transaction do
      relay&.destroy!
      case param_control_mechanism
      when Relay::CONTROL_MECHANISMS[:relay]
        create_relay!(attributes)
      when Relay::CONTROL_MECHANISMS[:timer]
        create_relay!(instrument: @product, type: "RelayDummy")
      when "manual"
        Relay.new # return a relay instance for the form to use
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed
    relay # returns invalid object for error handling
  end

end
