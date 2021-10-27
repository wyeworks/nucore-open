# frozen_string_literal: true

module SecureRooms

  module UserExtension

    extend ActiveSupport::Concern

    included do
      validates :card_number, uniqueness: { allow_blank: true, case_sensitive: false }
      validates :i_class_number, uniqueness: { allow_blank: true, case_sensitive: false }

      def self.for_card_number(card_number)
        find_by(card_number: card_number) || find_by(card_number: card_number.split("-").first)
      end
    end

  end

end
