# frozen_string_literal: true

class ResearchSafetyCertificatesController < GlobalSettingsController

  before_action :load_certificate, only: [:edit, :update, :destroy]

  def index
    @certificates = ResearchSafetyCertificate.ordered
  end

  def new
    @certificate = ResearchSafetyCertificate.new
  end

  def create
    @certificate = ResearchSafetyCertificate.new(certificate_params)

    if @certificate.save
      flash[:notice] = text('create.notice', certificate_name: @certificate.name)
      redirect_to action: :index
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @certificate.update_attributes(certificate_params)
      flash[:notice] = text('update.notice', certificate_name: @certificate.name)
      redirect_to action: :index
    else
      render :edit
    end
  end

  def destroy
    if @certificate.destroy
      @certificate.update_attributes(deleted_by_id: current_user.id)
      flash[:notice] = text('destroy.notice', certificate_name: @certificate.name)
    else
      flash[:error] = text('destroy.error', certificate_name: @certificate.name)
    end

    redirect_to action: :index
  end

  private

  def certificate_params
    params.require(:research_safety_certificate).permit(:name)
  end

  def load_certificate
    @certificate = ResearchSafetyCertificate.find(params[:id])
  end

end
