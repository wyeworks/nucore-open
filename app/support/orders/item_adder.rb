# frozen_string_literal: true

class Orders::ItemAdder

  # timed services default to 1 minute (arbitrary)
  DEFAULT_TIMED_SERVICES_DURATION = 1

  def initialize(order)
    @order = order
  end

  def add(product, quantity = 1, attributes = {})
    check_for_mixed_facility! product
    quantity = quantity.to_i
    # Only TimedServices care about duration
    duration = attributes.delete(:duration)

    return [] if quantity <= 0

    ods = case product
          when Bundle
            add_bundles(product, quantity, attributes)
          when Service
            add_services(product, quantity, attributes)
          when TimedService
            add_timed_services(product, quantity, duration, attributes)
          when Instrument
            add_instruments(product, quantity, attributes)
          else
            [create_order_detail({ product: product, quantity: quantity }.merge(attributes))]
          end
    ods || []
  end

  # Returns true if adding the product creates multiple line items if you add a
  # quantity greater than 1.
  def self.multiline?(product)
    case product
    when Service
      product.active_template? || product.active_survey?
    when Bundle, TimedService, Instrument
      true
    else
      false
    end
  end

  private

  def check_for_mixed_facility!(product)
    if product.facility != @order.facility
      if @order.order_details.length > 0
        raise NUCore::MixedFacilityCart
      else
        @order.update_attributes(facility: product.facility)
      end
    end
  end

  # If the service has a survey or order form, a quantity of more than one will
    # result in
  def add_instruments(product, quantity, attributes)
    Array.new(quantity) do
      create_order_detail({ product: product, quantity: 1 }.merge(attributes))
    end
  end

  def add_timed_services(product, quantity, duration, attributes)
    Array.new(quantity) do
      create_order_detail({ product: product, quantity: duration || DEFAULT_TIMED_SERVICES_DURATION }.merge(attributes))
    end
  end

  # If the service has a survey or order form, we create one row for each quantity since
  # each one will require a separate upload form.
  def add_services(product, quantity, attributes)
    separate = (product.active_template? || product.active_survey?)
    # can't add single order_detail for service when it requires a template or a survey.
    # number of order details to add
    repeat = separate ? quantity : 1
    # quantity to add them with
    individual_quantity = separate ? 1 : quantity

    Array.new(repeat) do
      create_order_detail({ product: product, quantity: individual_quantity }.merge(attributes))
    end
  end

  def add_bundles(product, quantity, attributes = {})
    quantity.times.inject([]) { |ods, _i| ods.concat create_bundle_order_detail(product, attributes) }
  end

  def create_bundle_order_detail(product, attributes = {})
    group_id = @order.max_group_id + 1
    product.bundle_products.flat_map do |bundle_product|
      # When inside a bundle, we want each reservation to end up on its own order detail,
      # while all other types will result in a single line item. This is true even
      # for services which have an order form/survey.
      case bundle_product.product
      when Instrument
        add_instruments(bundle_product.product, bundle_product.quantity, { bundle: product, group_id: group_id }.merge(attributes))
      else
        create_order_detail(
          {
            product: bundle_product.product,
            quantity: bundle_product.quantity,
            bundle: product,
            group_id: group_id,
          }.merge(attributes),
        )
      end
    end
  end

  def create_order_detail(options)
    options.reverse_merge!(
      quantity: 1,
      account: @order.account,
      created_by: @order.created_by,
    )
    @order.order_details.create!(options)
  end

end
