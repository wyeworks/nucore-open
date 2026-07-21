# frozen_string_literal: true

module BulkEmail

  class JobDecorator < SimpleDelegator

    include DateHelper

    def to_model
      self
    end

    def sender
      user.email
    end

    def recipient_list
      recipients.join(", ")
    end

    def products
      @products ||=
        Product.where(id: selected_product_ids).pluck(:name).join(", ")
    end

    def facilities
      @facilities ||=
        Facility.where(id: search_criteria["facilities"]).join(", ")
    end

    def start_date
      formatted_search_date("start_date")
    end

    def end_date
      formatted_search_date("end_date")
    end

    def user_types
      search_criteria["bulk_email"]["user_types"].map do |user_type|
        I18n.t(user_type, scope: "bulk_email.user_type", default: user_type.titleize)
      end.join(", ")
    end

    private

    def formatted_search_date(key)
      value = search_criteria[key]
      return I18n.t("bulk_email.dates.unset") if value.blank?

      parsed = parse_iso_date(value)
      parsed ? format_usa_date(parsed) : value
    end

    def selected_product_ids
      ((search_criteria["products"] || []) << search_criteria["product_id"])
        .compact
        .map(&:to_i)
        .uniq
    end

  end

end
