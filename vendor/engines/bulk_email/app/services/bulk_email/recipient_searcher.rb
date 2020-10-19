# frozen_string_literal: true

module BulkEmail

  class RecipientSearcher

    include DateHelper
    include ActionView::Helpers::FormTagHelper

    attr_reader :search_fields, :facility

    DEFAULT_SORT = [:last_name, :first_name].freeze

    def initialize(facility, search_fields)
      @search_fields = search_fields
      @facility = facility
    end

    def self.user_types
      if SettingsHelper.feature_on?(:training_requests)
        %i(customers authorized_users training_requested account_owners)
      else
        %i(customers authorized_users account_owners)
      end
    end

    def user_types
      @user_types ||= self.class.user_types & selected_user_types
    end

    def do_search
      user_types.flat_map do |user_type|
        public_send(:"search_#{user_type}")
      end.uniq.sort_by { |u| [u.last_name, u.first_name] }
    end

    def has_search_fields?
      search_fields.present? && search_fields[:commit].present?
    end

    def search_params_as_hidden_fields
      [
        hidden_tags_for(:start_date, search_fields[:start_date]),
        hidden_tags_for(:end_date, search_fields[:end_date]),
        hidden_tags_for("bulk_email[user_types][]", search_fields[:bulk_email][:user_types]),
        hidden_tags_for("products[]", search_fields[:products]),
        hidden_tags_for("facilities[]", search_fields[:facilities]),
      ].flatten
    end

    def search_customers
      users
        .distinct
        .joins(orders: :order_details)
        .merge(filtered_order_details)
    end

    def search_account_owners
      users
        .distinct
        .joins(accounts: :order_details)
        .merge(AccountUser.owners)
        .merge(filtered_order_details)
    end

    def search_authorized_users
      users
        .distinct
        .joins(:product_users)
        .where(product_users: { product: products_from_params })
    end

    def search_training_requested
      users
        .distinct
        .joins(:training_requests)
        .where(training_requests: { product: products_from_params })
    end

    private

    def hidden_tags_for(key, values)
      Array(values).map { |value| hidden_field_tag(key, value, id: nil) }
    end

    def products_from_params
      query = Product.for_facility(facility).active.requiring_approval
      query = query.where(facility: search_fields[:facilities]) if search_fields[:facilities].present?
      query = query.where(id: search_fields[:products]) if search_fields[:products].present?
      query
    end

    def selected_user_types
      return [] unless has_search_fields? && search_fields[:bulk_email].present?
      search_fields[:bulk_email][:user_types].map(&:to_sym)
    end

    def users
      User.active
    end

    def filtered_order_details
      OrderDetail
        .for_products(search_fields[:products])
        .joins(:product)
        .merge(Product.active)
        .for_facility(facility) # If cross_facility, will not add any restrictions
        .for_facilities(search_fields[:facilities])
        .ordered_or_reserved_in_range(start_date, end_date)
    end

    def start_date
      parse_search_field_date(:start_date)
    end

    def end_date
      parse_search_field_date(:end_date)
    end

    def parse_search_field_date(date_field)
      return if search_fields[date_field].blank?
      parse_usa_date(search_fields[date_field].tr("-", "/"))
    end

  end

end
