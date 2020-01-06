# frozen_string_literal: true

class ProductResearchSafetyCertificationRequirementsController < ApplicationController

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
    @product_research_safety_certification_requirement = ProductResearchSafetyCertificationRequirement.new(product: @product)
    @available_certificates = available_certificates
    @product_certification_requirements = @product.product_research_safety_certification_requirements
  end

  def create
    certification_requirement = @product.product_research_safety_certification_requirements.build(product_research_safety_certification_requirement_params)
    if certification_requirement.save
      flash[:notice] = text("create.notice", certificate_name: certification_requirement.research_safety_certificate.name)
    else
      flash[:error] = text("create.error", certificate_name: certification_requirement.research_safety_certificate.name)
    end
    redirect_to action: :index
  end

  def destroy
    if @product_research_safety_certification_requirement.destroy
      @product_research_safety_certification_requirement.update_attributes(deleted_by_id: current_user.id)
      flash[:notice] = text("destroy.notice", certificate_name: @product_research_safety_certification_requirement.research_safety_certificate.name)
    else
      flash[:error] = text("destroy.error", certificate_name: @product_research_safety_certification_requirement.research_safety_certificate.name)
    end
    redirect_to action: :index
  end

  private

  def available_certificates
    ResearchSafetyCertificate.order(:name) - @product.research_safety_certificates
  end

  def init_product
    @product = current_facility.products.find_by!(url_name: params[:product_id])
  end

  def product_research_safety_certification_requirement_params
    params.require(:product_research_safety_certification_requirement).permit(:nu_safety_certificate_id)
  end

end
