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
    order_number: "Order",
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

  cattr_accessor(:importable_product_types) { [Item, Service, TimedService] }

  attr_accessor :order_import, :order
  delegate :id, to: :order, prefix: true
  delegate :facility, to: :order_import

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
      .for_facility(facility)
      .active.find_by(account_number: field(:chart_string))
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
    @order_date ||= parse_usa_import_date(field(:order_date))
  end

  def order_key
    @order_key ||= [field(:user), field(:chart_string), field(:order_date)]
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
    @user ||= User.find_by(username: field(:user)) || User.find_by(email: field(:user))
  end

  def product
    @product ||=
      @order_import
      .facility
      .products
      .not_archived
      .find_by(name: field(:product_name))
  end

  def add_error(message)
    @errors.add(message) if message.present?
  end

  private

  def add_product_to_order
    ActiveRecord::Base.transaction do
      begin
        @order = field(:order_number).present? ? existing_order : @order_import.fetch_or_create_order!(self)
        # The order adding feature has some quirky behavior because of the "order form"
        # feature: if you add multiple of a timed service, it creates multiple line items
        # in your cart. Also, in the "add to order" feature, there is a separate `duration`
        # field. To account for this idiosyncrasy, we need to handle it as a special case.
        if product.quantity_as_time?
          @order_details = order.add(product, 1, duration: field(:quantity), note: field(:notes))
        else
          @order_details = order.add(product, field(:quantity), note: field(:notes))
        end
        purchase_order! unless order.purchased?
        backdate_order_details_to_complete!
      rescue ActiveRecord::RecordInvalid => e
        add_error(e.message)
        raise ActiveRecord::Rollback
      end
    end
  end

  def purchase_order!
    if order.validate_order!
      add_error("Couldn't purchase order") unless order.purchase_without_default_status!
    else
      add_error("Couldn't validate order")
    end
  end

  def backdate_order_details_to_complete!
    @order_details.each do |order_detail|
      order_detail.ordered_at = order_date
      order_detail.backdate_to_complete!(fulfillment_date)
    end
  end

  def field(field)
    @row[HEADERS[field]].to_s.try(:strip)
  end

  def fulfillment_date
    @fulfillment_date ||= parse_usa_import_date(field(:fulfillment_date))
  end

  def existing_order
    return @existing_order if defined?(@existing_order)

    @existing_order = Order.find_by(id: field(:order_number))
  end

  def has_valid_headers?
    validate_headers
    !errors?
  end

  def validate_headers
    missing_headers = REQUIRED_HEADERS - @row.headers
    add_error("Missing headers: #{missing_headers.join(' | ')}") if missing_headers.present?
  end

  def has_valid_fields?
    validate_fields
    !errors?
  end

  def validate_fields
    validate_fulfillment_date
    validate_order_date
    validate_user
    validate_product
    validate_account
    validate_existing_order
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

  def validate_user
    add_error("Invalid username or email") if user.blank?
  end

  def validate_product
    if product.blank?
      add_error("Couldn't find product by name '#{field(:product_name)}'")
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

  def validate_account
    return if user.blank? || product.blank?
    if account.present?
      add_error(account.validate_against_product(product, user))
    else
      add_error("Can't find account")
    end
  end

  def validate_existing_order
    # Don't run these validations if we're not dealing with an existing order
    return unless field(:order_number).present?

    if existing_order.blank?
      add_error("The order could not be found")
    elsif !existing_order.purchased?
      add_error("The order has not been purchased")
    elsif existing_order.facility != facility
      add_error("The order belongs to another facility")
    elsif existing_order.user != user
      add_error("The user does not match the existing order's")
    end
  end

end
