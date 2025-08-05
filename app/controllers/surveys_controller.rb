# frozen_string_literal: true

class SurveysController < ApplicationController

  admin_tab     :all
  before_action :check_acting_as, except: :complete
  before_action :init_current_facility
  before_action :init_service
  before_action :init_survey, only: [:activate, :deactivate]

  load_and_authorize_resource class: "ExternalService"

  def initialize
    @active_tab = "admin_products"
    super
  end

  # PUT /facilities/1/services/1/surveys/2/activate
  def activate
    @survey.activate
    flash[:notice] = "Survey activated"
    redirect_to request.referer
  end

  # PUT /facilities/1/services/1/surveys/2/deactivate
  def deactivate
    @survey.deactivate
    flash[:notice] = "Survey de-activated"
    redirect_to request.referer
  end

  def complete
    begin
      SurveyResponse.new(params).save!
    rescue => e
      Rails.logger.error("Could not save external survey response! #{e.message}\n#{e.backtrace.join("\n")}")
    end

    if request.xhr?
      # send the supplied string to the browser with a MIME type of text/javascript
      render :js => "window.location = '#{params[:referer]}'"
    else
      # TO DO: Remove logging when the other consumers of this code path are better understood.
      # This action should not be available via GET, but we need to know more before making that change.
      Rails.logger.info("Non-Form.io survey completed for Order detail: #{params[:receiver_id]}, external service: #{params[:external_service_id]}")
      redirect_to params[:referer]
    end
  end

  private

  def init_survey
    @survey = Survey.new @service, params
  end

  def init_service
    @service = current_facility.services.find_by!(url_name: params[:service_id])
  end

end
