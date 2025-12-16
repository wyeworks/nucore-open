# frozen_string_literal: true

class Accessories::Accessorizer

  def initialize(order_detail)
    @order_detail = order_detail
  end

  def add_accessory(accessory, options = {})
    new_order_detail = build_accessory_order_detail(accessory, options)
    # match the order status to that of the parent
    new_order_detail.update_order_status! nil, @order_detail.order_status
    new_order_detail
  end

  def unpurchased_accessories
    @order_detail.product.accessories.not_archived.reject { |a| current_accessories.include? a }
  end

  # Returns the accessories for the product, but excludes all the accessories that
  # have already been ordered
  def unpurchased_accessory_order_details
    unpurchased_accessories.map { |a| build_accessory_order_detail(a) }
  end

  def accessory_order_details
    @order_detail.product.accessories.not_archived.map { |a| find_or_build_accessory_order_detail(a) }
  end

  def build_accessory_order_detail(accessory, options = {})
    return nil unless valid_accessory?(accessory)
    od = @order_detail.child_order_details.build(detail_attributes(accessory, options))
    decorated_od = decorate(od)
    decorated_od.update_quantity
    decorated_od
  end

  def update_unpurchased_attributes(params)
    update_attributes_of(unpurchased_accessory_order_details, params)
  end

  def update_accessorizer_attributes(params)
    update_attributes_of(accessory_order_details, params)
  end

  def update_order_detail(od, params)
    if %w(true 1).include? params[:enabled]
      assign_attributes_and_save(od, params)
    else
      od.destroy
    end
    od
  end

  def build_order_details_from(params)
    order_details = accessory_order_details.collect do |od|
      detail_params = params[od.product_id.to_s]
      od.assign_attributes(detail_params.permit(:enabled, :quantity, :note)) if detail_params
      od
    end
  end

  private

  def update_attributes_of(order_details, params)
    response = nil
    @order_detail.transaction do
      order_details = order_details.collect do |od|
        # begin/rescue each to make sure that validations happen
        # for all order details
        begin
          detail_params = params[od.product_id.to_s]
          update_order_detail(od, detail_params) if detail_params
        rescue ActiveRecord::RecordInvalid
          # UpdateResponse will check #errors on each od
        end
        od
      end

      response = Accessories::UpdateResponse.new(order_details)
      raise ActiveRecord::Rollback unless response.valid?
    end
    response
  end

  def assign_attributes_and_save(od, params)
    od.assign_attributes(permitted_attributes(params))
    od.update_quantity # so auto-scaled overrides the parameter
    od.assign_estimated_price
    od.enabled = true

    validate_note!(od)

    # Always use the accessory product's initial order status,
    # regardless of the parent's status. Accessories should be independent.
    od.order_status_id = od.product.initial_order_status.id
    od.save!
  end

  def validate_note!(od)
    order_detail = od.respond_to?(:order_detail) ? od.order_detail : od
    unless NotePresenceValidator.new(order_detail).valid?
      raise ActiveRecord::RecordInvalid, order_detail
    end
  end

  def permitted_attributes(params)
    params.except(:enabled).permit(:quantity, :note)
  end

  def product_accessory(accessory)
    @order_detail.product.product_accessory_by_id(accessory.id)
  end

  def valid_accessory?(accessory)
    @order_detail.product.accessories.include? accessory
  end

  def decorate(order_detail)
    Accessories::Scaling.decorate(order_detail)
  end

  def detail_attributes(accessory, options)
    attrs = @order_detail.attributes.slice("account_id", "created_by", "ordered_at")
    attrs.merge(
      order: @order_detail.order,
      product: accessory,
      note: options[:note],
      quantity: options[:quantity],
      product_accessory: product_accessory(accessory),
      state: "new",
    )
  end

  def current_accessories
    @order_detail.child_order_details.map(&:product)
  end

  def find_or_build_accessory_order_detail(accessory)
    if existing_od = @order_detail.child_order_details.find { |od| od.product == accessory }
      decorated = decorate(existing_od)
      decorated.enabled = true
      decorated.update_quantity
      decorated
    else
      build_accessory_order_detail(accessory)
    end
  end

end
