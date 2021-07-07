# frozen_string_literal: true

require "csv"

module Reports

  class ProductAccessListCsvReport
    include DateHelper
    include TextHelpers::Translation

    def initialize(product_name, product_users)
      @product_name = product_name
      @product_users = product_users
    end

    def to_csv
      CSV.generate do |csv|
        csv << headers
        @product_users.each do |product_user|
          csv << build_row(product_user)
        end
      end
    end

    def filename
      "#{@product_name.parameterize}_access_list.csv"
    end

    def description
      text(".subject")
    end

    def text_content
      text(".body")
    end

    def has_attachment?
      true
    end

    def translation_scope
      "reports.product_users"
    end

    private

    def headers
      [
        User.human_attribute_name(:username),
        User.human_attribute_name(:full_name),
        text(".user_status"),
        User.human_attribute_name(:email),
        ProductAccessGroup.model_name.human,
        text(".date_added"),
      ]
    end

    def build_row(product_user)
      user = product_user.user
      [
        user.username,
        user.full_name,
        user_status(user),
        user.email,
        product_user.product_access_group.try(:name),
        format_usa_datetime(product_user.approved_at),
      ]
    end

    def user_status(user)
      return "Active" if user.active?
      user.suspended? ? "Suspended" : "Expired"
    end
  end

end
