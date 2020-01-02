# frozen_string_literal: true

module NuResearchSafety

  class CertificatesController < GlobalSettingsController

    before_action :load_certificate, only: [:edit, :update, :destroy]

    def index
      @certificates = NuResearchSafety::Certificate.ordered
    end

    def new
      @certificate = NuResearchSafety::Certificate.new
    end

    def create
      @certificate = NuResearchSafety::Certificate.new(certificate_params)

      if @certificate.save
        flash[:notice] = text('.create.notice', certificate_name: @certificate.name)
        redirect_to certificates_path
      else
        render :new
      end
    end

    def edit
    end

    def update
      if @certificate.update_attributes(certificate_params)
        flash[:notice] = text('.update.notice', certificate_name: @certificate.name)
        redirect_to certificates_path
      else
        render :edit
      end
    end

    def destroy
      if @certificate.destroy
        @certificate.update_attributes(deleted_by_id: current_user.id)
        flash[:notice] = text('.destroy.notice', certificate_name: @certificate.name)
      else
        flash[:error] = text('.destroy.error', certificate_name: @certificate.name)
      end

      redirect_to certificates_path
    end

    private

    def certificate_params
      params.require(:nu_research_safety_certificate).permit(:name)
    end

    def load_certificate
      @certificate = NuResearchSafety::Certificate.find(params[:id])
    end

  end

end
