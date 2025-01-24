# frozen_string_literal: true

module SangerSequencing

  module SangerEnabledProduct

    extend ActiveSupport::Concern

    included do
      has_one :sanger_product, class_name: "SangerSequencing::SangerProduct", foreign_key: :product_id
    end

    def create_sanger_product_with_default_primers
      transaction do
        create_sanger_product.tap(&:create_default_primers)
      end
    end

  end

end
