# frozen_string_literal: true

require "date_helper" # parse_usa_import_date

class OrderRowImporter

  include DateHelper

  HEADERS = [
    :user,
    :chart_string,
    :product_name,
    :quantity,
    :order_date,
    :fulfillment_date,
    :notes,
    :order_number,
    :reference_id,
    :errors,
  ].lazy.map { |k| header(k) }

  REQUIRED_HEADERS = [
    :user,
    :chart_string,
    :product_name,
    :quantity,
    :order_date,
    :fulfillment_date,
  ].lazy.map { |k| header(k) }

  cattr_accessor(:importable_product_types) { [Item, Service, TimedService] }

  attr_accessor :order_import, :order
  delegate :id, to: :order, prefix: true
  delegate :facility, to: :order_import

  def self.order_key_for_row(row)
    new(row, nil).order_key
  end

  def self.header(header)
    I18n.t(header, scope: "#{name.underscore}.headers", default: header.to_s.titleize)
  end

  def header(header)
    self.class.header(header)
  end

  def self.headers_to_s
    HEADERS.to_a.join(",")
  end

  def self.optional_fields
    (HEADERS.to_a - REQUIRED_HEADERS.to_a - [header(:errors)]).to_sentence
  end

  def self.importable_products
    importable_product_types.map { |type| type.name.titleize }.to_sentence
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
    @order_key ||= field(:order_number).presence || [field(:user).downcase, field(:chart_string).downcase, field(:order_date)]
  end

  def row_with_errors
    # Start with a hash of HEADERS keys with nil values to ensure optional columns
    # are included in the report even if they are not in the uploaded CSV.
    new_row = HEADERS.each_with_object({}) { |header, hash| hash[header] = nil }
    new_row.merge!(@row)
    new_row[header(:errors)] = errors.join(", ")

    CSV::Row.new(new_row.keys, new_row.values)
  end

  def user
    @user ||= User.find_by(username: field(:user).downcase) || User.find_by(email: field(:user).downcase)
  end

  def product
    @product ||=
      @order_import
      .facility
      .products
      .not_archived
      .find_by(name: field(:product_name))
  end

  def add_error(message, options = {})
    if message.present?
      message = I18n.t(message, options.reverse_merge(scope: "#{self.class.name.underscore}.errors")) if message.is_a?(Symbol)
      @errors.add(message)
    end
  end

  private

  def add_product_to_order
    ActiveRecord::Base.transaction do
      begin
        @order = field(:order_number).present? ? existing_order : @order_import.fetch_or_create_order!(self)

        attributes = { note: field(:notes), account: account, reference_id: field(:reference_id) }
        # The order adding feature has some quirky behavior because of the "order form"
        # feature: if you add multiple of a timed service, it creates multiple line items
        # in your cart. Also, in the "add to order" feature, there is a separate `duration`
        # field. To account for this idiosyncrasy, we need to handle it as a special case.
        if product.quantity_as_time?
          @order_details = order.add(product, 1, attributes.merge(duration: field(:quantity)))
        else
          @order_details = order.add(product, field(:quantity), attributes)
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
      add_error(:purchase_fail) unless order.purchase_without_default_status!
    else
      add_error(:validate_fail)
    end
  end

  def backdate_order_details_to_complete!
    @order_details.each do |order_detail|
      order_detail.ordered_at = order_date
      order_detail.backdate_to_complete!(fulfillment_date)
    end
  end

  def field(field)
    @row[header(field)].to_s.try(:strip)
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
    missing_headers = REQUIRED_HEADERS.to_a - @row.headers
    add_error(:missing_headers, headers: missing_headers.join(' | ')) if missing_headers.present?
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
      add_error(:invalid_date, field: header(:fulfillment_date))
    # Because it's parsed as a date, it gets parsed as midnight at the beginning of that day,
    # which allows placing the order for today.
    elsif fulfillment_date.future?
      add_error(:cannot_be_in_future, field: header(:fulfillment_date))
    end
  end

  def validate_order_date
    if order_date.blank?
      add_error(:invalid_date, field: header(:order_date))
    # Because it's parsed as a date, it gets parsed as midnight at the beginning of that day,
    # which allows placing the order for today.
    elsif order_date.future?
      add_error(:cannot_be_in_future, field: header(:order_date))
    end
  end

  def validate_user
    add_error(:invalid_user) if user.blank?
  end

  def validate_product
    if product.blank?
      add_error(:product_not_found, product: field(:product_name))
    else
      validate_product_is_importable
    end
  end

  def validate_product_is_importable
    unless product.class.in?(importable_product_types)
      add_error(:invalid_product_type, type: product.class.model_name.human)
    end

    if product.is_a?(Service)
      add_error(:requires_survey, type: product.class.model_name.human) if product.active_survey?
      add_error(:requires_template, type: product.class.model_name.human) if product.active_template?
    end
  end

  def validate_account
    return if user.blank? || product.blank?
    if account.present?
      add_error(account.validate_against_product(product, user))
    else
      add_error(:account_not_found)
    end
  end

  def validate_existing_order
    # Don't run these validations if we're not dealing with an existing order
    return unless field(:order_number).present?

    if existing_order.blank?
      add_error(:order_not_found)
    elsif !existing_order.purchased?
      add_error(:order_not_purchased)
    elsif existing_order.facility != facility
      add_error(:order_in_other_facility)
    elsif existing_order.user != user
      add_error(:order_user_mismatch)
    end
  end
end
