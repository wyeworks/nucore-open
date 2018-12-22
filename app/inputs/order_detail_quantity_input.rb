# frozen_string_literal: true

class OrderDetailQuantityInput < QuantityInput

  def hint(_wrapper_options = nil)
    if object.scaling_type && !object.quantity_editable?
      @hint ||= I18n.t("product_accessories.type.#{object.scaling_type}")
    end
  end

  private

  def has_disabled?
    !object.quantity_editable?
  end

end
