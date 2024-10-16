# frozen_string_literal: true

module BulkEmail

  class ContentGenerator

    include TextHelpers::Translation

    attr_reader :facility, :subject_product

    def initialize(facility, subject_product = nil)
      @facility = facility
      @subject_product = subject_product
    end

    def subject_prefix
      if facility.single_facility?
        text("subject_prefix_with_facility", name: facility.name, abbreviation: facility.abbreviation)
      else
        text("subject_prefix")
      end
    end

    def wrap_text(text)
      [greeting, text].compact.join("\n\n")
    end

    def greeting
      [
        text("body.greeting"),
        reason_statement,
      ].compact.join("\n\n")
    end

    def translation_scope
      "bulk_email"
    end

    private

    def reason_statement
      return if subject_product.blank? || subject_product.online?
      I18n.t(subject_product.offline_category,
             product_name: subject_product.name,
             scope: "bulk_email.product_unavailable_reason_statements",
             default: :other)
    end

  end

end
