# frozen_string_literal: true

class TimedServicesController < ProductsCommonController

  def create
    if resource_params[:pricing_mode] == TimedService::Pricing::DURATION && cannot?(:create_duration_billing, TimedService)
      flash.now[:error] = t("controllers.timed_services.create.duration_billing_not_authorized")

      render :new
    else
      super
    end
  end

  private

  def permitted_params
    params = super

    params -= [:pricing_mode] if action_name == "update"

    params
  end

end
