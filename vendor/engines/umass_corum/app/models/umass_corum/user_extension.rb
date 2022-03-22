# frozen_string_literal: true

module UmassCorum

  module UserExtension

    extend ActiveSupport::Concern
  
    included do
      validates :umass_emplid, uniqueness: { allow_blank: true, case_sensitive: true, on: :create, unless: :subsidiary_account? }
    end

  end

end
