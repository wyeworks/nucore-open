# frozen_string_literal: true

class InstrumentForCart < ProductForCart

  private

  def checks(acting_user)
    [check_that_user_is_present(acting_user), check_that_product_has_schedule_rules] + super
  end

  def check_that_user_is_present(user)
    -> { @error_path = url_helpers.new_user_session_path if user.blank? }
  end

  def check_that_product_has_schedule_rules
    -> { @error_message = text(".schedule_not_available", i18n_params) if product.schedule_rules.none? }
  end

end
