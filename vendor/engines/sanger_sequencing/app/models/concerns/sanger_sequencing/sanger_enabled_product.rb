# frozen_string_literal: true

module SangerSequencing

  module SangerEnabledProduct

    extend ActiveSupport::Concern

    included do
      has_one :sanger_product, class_name: "SangerSequencing::SangerProduct", foreign_key: :product_id
    end

  end

end
