# frozen_string_literal: true

class ProductForCart

  include TextHelpers::Translation

  attr_accessor :error_message
  attr_accessor :error_path

  def initialize(product, quick_reservation: false)
    @product = product
    @quick_reservation = quick_reservation
  end

  def purchasable_by?(acting_user, session_user)
    raise NUCore::PermissionDenied unless product.is_accessible_to_user?(session_user)

    checks(acting_user, session_user).all? do |check|
      result = check.call
      [error_path, error_message].all?(&:blank?) && result != false
    end
  end

  protected

  def translation_scope
    "models.#{self.class.name.underscore}"
  end

  private

  attr_accessor :product

  def checks(acting_user, session_user)
    [
      check_that_user_is_present(acting_user),
      check_that_product_is_available_for_purchase,
      check_that_product_has_price_policies,
      check_that_product_can_be_used(acting_user, session_user),
      check_that_product_has_price_groups_accessible_to_user(acting_user),
      check_that_user_has_accounts_for_product(acting_user),
      check_that_session_user_can_order_on_behalf_of_assumed_user(acting_user, session_user),
    ]
  end

  def check_that_user_is_present(user)
    -> { user.present? }
  end

  def check_that_product_is_available_for_purchase
    -> { @error_message = text(".not_available", i18n_params) unless product.available_for_purchase? }
  end

  def check_that_product_has_price_policies
    proc do
      price_policies = product.is_a?(Bundle) ? product.products.flat_map(&:price_policies) : product.price_policies
      @error_message = text(".pricing_not_available", i18n_params) if price_policies.none?
    end
  end

  def check_that_product_can_be_used(acting_user, session_user)
    proc do
      if !product.can_be_used_by?(acting_user) && !(session_user.present? && session_user.can_override_restrictions?(product))
        if SettingsHelper.feature_on?(:training_requests) && product.allows_training_requests?
          if TrainingRequest.submitted?(session_user, product)
            @error_message = text("models.product_for_cart.already_requested_access", i18n_params)
            @error_path = url_helpers.facility_path(product.facility)
          else
            @error_message = html("requires_approval", i18n_params) if @quick_reservation
            @error_path = url_helpers.new_facility_product_training_request_path(product.facility, product)
          end
        else
          @error_message = html("requires_approval", i18n_params)
        end
      end
    end
  end

  def check_that_product_has_price_groups_accessible_to_user(user)
    proc do
      price_group_ids = if product.nonbillable_mode?
                          [PriceGroup.nonbillable.id]
                        else
                          (user.price_groups + user.account_price_groups).flatten.uniq.map(&:id)
                        end

      @error_message = text(".no_price_groups", i18n_params) unless product.can_purchase?(price_group_ids)
    end
  end

  def check_that_user_has_accounts_for_product(user)
    -> { @error_message = text(".no_accounts", i18n_params) if user.accounts_for_product(product).none? }
  end

  def check_that_session_user_can_order_on_behalf_of_assumed_user(acting_user, session_user)
    proc do
      if acting_as?(acting_user, session_user) && !session_user.operator_of?(product.facility)
        @error_message = text(".not_authorized_to_order_on_behalf", i18n_params)
      end
    end
  end

  def i18n_params
    product_type = product.class.model_name.human.downcase
    {
      email: product.email,
      facility: product.facility,
      product_name: product.name,
      product_type: product_type,
      product_type_plural: product_type.pluralize,
    }
  end

  def url_helpers
    Rails.application.routes.url_helpers
  end

  def acting_as?(acting_user, session_user)
    return false if session_user.nil?
    !acting_user.equal?(session_user)
  end

end
