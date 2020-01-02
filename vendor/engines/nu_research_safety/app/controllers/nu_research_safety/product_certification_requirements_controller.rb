# frozen_string_literal: true

module NuResearchSafety

  class ProductCertificationRequirementsController < ApplicationController

    admin_tab     :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :init_product
    load_and_authorize_resource through: :product

    layout "two_column"

    def initialize
      @active_tab = "admin_products"
      super
    end

    def index
      @product_certification_requirement = NuResearchSafety::ProductCertificationRequirement.new(product: @product)
      @available_certificates = available_certificates
      @product_certification_requirements = @product.product_certification_requirements
    end

    def create
      certification_requirement = @product.product_certification_requirements.build(product_certification_requirement_params)
      if certification_requirement.save
        flash[:notice] = text("create.notice", certificate_name: certification_requirement.certificate.name)
      else
        flash[:error] = text("create.error", certificate_name: certification_requirement.certificate.name)
      end
      redirect_to action: :index
    end

    def destroy
      if @product_certification_requirement.destroy
        @product_certification_requirement.update_attributes(deleted_by_id: current_user.id)
        flash[:notice] = text("destroy.notice", certificate_name: @product_certification_requirement.certificate.name)
      else
        flash[:error] = text("destroy.error", certificate_name: @product_certification_requirement.certificate.name)
      end
      redirect_to action: :index
    end

    private

    def available_certificates
      NuResearchSafety::Certificate.order(:name) - @product.certificates
    end

    def init_product
      @product = current_facility.products.find_by!(url_name: params[:product_id])
    end

    def product_certification_requirement_params
      params.require(:nu_research_safety_product_certification_requirement).permit(:nu_safety_certificate_id)
    end

  end

end
