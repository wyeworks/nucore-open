# frozen_string_literal: true

class ServicesController < ProductsCommonController
  after_action :update_sanger_external_service, only: [:create, :update]

  def sanger
    authorize! :view_details, @product

    if request.patch? && can?(:manage, current_facility)
      if @product.update(sanger_params)
        flash[:notice] = t("controllers.services.sanger_config_updated")
      end
    end
  end

  private

  def permitted_params
    params = super

    if current_facility.sanger_sequencing_enabled?
      params += %i[sanger_sequencing_enabled]
    end

    params
  end

  def sanger_params
    params.require(:service).permit(:sanger_sequencing_primer)
  end

  def update_sanger_external_service
    return unless @product.sanger_sequencing_enabled_previously_changed?

    if @product.sanger_sequencing_enabled?
      ensure_sanger_url_service
      flash[:info] = t("controllers.services.sanger_sequencing_enabled")
    else
      flash[:info] = t("controllers.services.sanger_sequencing_disabled")
    end
  end

  ##
  # Ensures UrlService exists for the product
  # pointing to Sanger Submission
  def ensure_sanger_url_service
    sanger_external_service =
      @product
      .external_services
      .matching_location(new_sanger_sequencing_submission_path)
      .first

    if sanger_external_service.blank?
      ActiveRecord.transaction do
        external_service = UrlService.find_or_create_by(
          location: new_sanger_sequencing_submissions_path
        )
        ExeternalServicePasser.create(
          external_service:,
          passer: @product,
        )
      end
    end
  end
end
