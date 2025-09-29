# frozen_string_literal: true

module SecureRooms

  class CardReader < ApplicationRecord

    MAC_ADDRESS_FORMAT = /\A([0-9A-F]{2}:){5}([0-9A-F]{2})\z/

    belongs_to :secure_room, foreign_key: :product_id

    delegate :facility, to: :secure_room

    def ingress
      direction_in
    end

    def ingress=(value)
      self.direction_in = value
    end

    validates :product_id, presence: true
    validates :control_device_number, presence: true, format: { with: MAC_ADDRESS_FORMAT }
    validates :card_reader_number, presence: true, uniqueness: { scope: :control_device_number , case_sensitive: false }
    validates :tablet_token, uniqueness: { case_sensitive: false }

    before_validation :clean_mac_address
    before_create :set_tablet_token

    def self.ingress
      where(ingress: true)
    end

    def self.egress
      where(ingress: false)
    end

    def egress?
      !ingress?
    end

    def direction
      I18n.t("human_direction.#{direction_in}", scope: attribute_translation_scope)
    end

    def direction_options
      I18n.t("human_direction", scope: attribute_translation_scope).invert.to_a
    end

    private

    def attribute_translation_scope
      "#{self.class.i18n_scope}.attributes.#{model_name.i18n_key}"
    end

    def set_tablet_token
      return if tablet_token.present?

      # Generate random tokens until it finds one that doesn't already exist
      self.tablet_token = loop do
        token = ("A".."Z").to_a.sample(12).join
        break token if self.class.find_by(tablet_token: token).blank?
      end
    end

    def clean_mac_address
      self.control_device_number = control_device_number.to_s.upcase.tr("-", ":")
    end

  end

end
