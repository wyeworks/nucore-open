# frozen_string_literal: true

module Products::RelaySupport

  extend ActiveSupport::Concern

  included do
    has_one  :relay, inverse_of: :instrument, dependent: :destroy
    has_many :instrument_statuses, foreign_key: "instrument_id"

    accepts_nested_attributes_for :relay

    attr_writer :control_mechanism

    before_validation :destroy_and_init_relay, if: :control_mechanism

    validate :check_relay_with_right_type, if: :control_mechanism
  end

  # control mechanism for instrument
  def control_mechanism
    @control_mechanism || relay.try(:control_mechanism)
  end

  def current_instrument_status
    instrument_statuses.order("created_at DESC").first
  end

  def has_real_relay?
    relay && !relay.is_a?(RelayDummy) && relay.ip? && relay.outlet?
  end

  private ###################################

  # this is necessary because when rails builds the attached relay
  # and merges the attributes the relay's class is either:
  #
  # 1) whatever it was before the user changed it (value of type field from db)
  # 2) Relay (the super class needed for STI) (if there was no relay attached to this instrument)
  #
  # in order to validate the relay properly we need to cast it
  # and populate self.errors ourselves
  def check_relay_with_right_type
    # only run this if passed in control_mechanism and relay
    return true if relay.nil? || control_mechanism == "manual"

    # transform to right type
    a_relay = relay.becomes(relay.type.constantize)
    # relay loses reference to instrument after #becomes
    a_relay.instrument = self

    # trigger validation of relay
    valid = a_relay.valid?

    # stuff relay's error messages into self.errors
    a_relay.errors.full_messages.each do |error_msg|
      errors[:relay] << error_msg
    end

    valid
  end

  # Don't bother with relay updates. STI + nested attributes
  # causes too much trouble. Just get rid of the old relay and
  # setup from scratch.
  def destroy_and_init_relay
    attrs = relay.try(:attributes) || {}
    relay.try :destroy

    case control_mechanism
    when Relay::CONTROL_MECHANISMS[:timer]
      self.relay = RelayDummy.new
    when Relay::CONTROL_MECHANISMS[:relay]
      build_relay attrs
    end
  end

end
