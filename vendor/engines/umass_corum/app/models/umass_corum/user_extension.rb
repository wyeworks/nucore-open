# frozen_string_literal: true

module UmassCorum

  module UserExtension

    extend ActiveSupport::Concern

    included do
      validates :umass_emplid, uniqueness: { allow_blank: true, case_sensitive: true, if: :check_umass_emplid? }

      def check_umass_emplid?
        !subsidiary_account? && umass_emplid_changed?
      end
    end

  end

end
