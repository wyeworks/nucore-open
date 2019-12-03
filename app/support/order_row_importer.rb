# frozen_string_literal: true

require "date_helper" # parse_usa_import_date

class OrderRowImporter

  include DateHelper

  HEADERS = {
    user: "Netid / Email",
    chart_string: "Chart String",
    product_name: "Product Name",
    quantity: "Quantity",
    order_date: "Order Date",
    fulfillment_date: "Fulfillment Date",
    notes: "Note",
    errors: "Errors",
  }.freeze

  REQUIRED_HEADERS = [
    :user,
    :chart_string,
    :product_name,
    :quantity,
    :order_date,
    :fulfillment_date,
  ].map { |k| HEADERS[k] }

  cattr_accessor(:importable_product_types) { [Item, Service] }

  def self.order_key_for_row(row)
    new(row, nil).order_key
  end

  def self.headers_to_s
    HEADERS.values.join(",")
  end

  def initialize(row, order_import)
    @row = row
    @order_import = order_import
    @errors = Set.new
  end

  def account
    @account ||=
      user
      .accounts
      .for_facility(product.facility)
      .active.find_by(account_number: account_number)
  end

  def errors?
    @errors.any?
  end

  def errors
    @errors.to_a
  end

  def import
    add_product_to_order if has_valid_headers? && has_valid_fields?
  end

  def order_date
    @order_date ||= parse_usa_import_date(order_date_field)
  end

  delegate :id, to: :order, prefix: true

  def order_key
    @order_key ||= [user_field, chart_string_field, order_date_field]
  end

  def row_with_errors
    # Start with a hash of HEADERS keys with nil values to ensure optional columns
    # are included in the report even if they are not in the uploaded CSV.
    new_row = HEADERS.values.each_with_object({}) { |header, hash| hash[header] = nil }
    new_row.merge!(@row)
    new_row[HEADERS[:errors]] = errors.join(", ")

    CSV::Row.new(new_row.keys, new_row.values)
  end

  def user
    @user ||=
      User.find_by(username: user_field) || User.find_by(email: user_field)
  end

  def add_error(message)
    @errors.add(message) if message.present?
  end

  private

  def account_number
    @account_number ||= @row[HEADERS[:chart_string]].try(:strip)
  end

  def add_product_to_order
    ActiveRecord::Base.transaction do
      begin
        @order_details = order.add(product, quantity, note: note)
        purchase_order! unless order.purchased?
        backdate_order_details_to_complete!
      rescue ActiveRecord::RecordInvalid => e
        add_error(e.message)
        raise ActiveRecord::Rollback
      end
    end
  end

  def backdate_order_details_to_complete!
    @order_details.each do |order_detail|
      order_detail.ordered_at = order_date
      order_detail.backdate_to_complete!(fulfillment_date)
    end
  end

  def chart_string_field
    @chart_string_field ||= @row[HEADERS[:chart_string]].try(:strip)
  end

  def fulfillment_date
    @fulfillment_date ||= parse_usa_import_date(fulfillment_date_field)
  end

  def fulfillment_date_field
    @fulfillment_date_field ||= @row[HEADERS[:fulfillment_date]].try(:strip)
  end

  def has_valid_headers?
    validate_headers
    !errors?
  end

  def has_valid_fields?
    validate_fields
    !errors?
  end

  def note
    @note ||= @row[HEADERS[:notes]].try(:strip)
  end

  def order
    @order ||= @order_import.fetch_or_create_order!(self)
  end

  def order_date_field
    @order_date_field ||= @row[HEADERS[:order_date]].try(:strip)
  end

  def product
    @product ||=
      @order_import
      .facility
      .products
      .not_archived
      .find_by(name: product_field)
  end

  def product_field
    @product_field ||= @row[HEADERS[:product_name]].try(:strip)
  end

  def purchase_order!
    if order.validate_order!
      add_error("Couldn't purchase order") unless order.purchase_without_default_status!
    else
      add_error("Couldn't validate order")
    end
  end

  def quantity
    @quantity ||= @row[HEADERS[:quantity]].to_i
  end

  def user_field
    @user_field ||= @row[HEADERS[:user]].try(:strip)
  end

  def validate_account
    return if user.blank? || product.blank?
    if account.present?
      add_error(account.validate_against_product(product, user))
    else
      add_error("Can't find account")
    end
  end

  def validate_headers
    missing_headers = REQUIRED_HEADERS - @row.headers
    add_error("Missing headers: #{missing_headers.join(' | ')}") if missing_headers.present?
  end

  def validate_fields
    validate_fulfillment_date
    validate_order_date
    validate_user
    validate_product
    validate_account
  end

  def validate_fulfillment_date
    if fulfillment_date.blank?
      add_error("Invalid Fulfillment Date: Please use MM/DD/YYYY format")
    end
  end

  def validate_order_date
    if order_date.blank?
      add_error("Invalid Order Date: Please use MM/DD/YYYY format")
    end
  end

  def validate_product
    if product.blank?
      add_error("Couldn't find product by name '#{product_field}'")
    else
      validate_product_is_importable
    end
  end

  def validate_product_is_importable
    unless product.class.in?(importable_product_types)
      add_error("import of #{product.class.model_name.human} orders not allowed at this time")
    end

    if product.is_a?(Service)
      add_error("Service requires survey") if product.active_survey?
      add_error("Service requires template") if product.active_template?
    end
  end

  def validate_user
    add_error("Invalid username or email") if user.blank?
  end

end
