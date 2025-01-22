# frozen_string_literal: true

module SangerSequencing

  class SubmissionsController < BaseController

    NEW_IDS_COUNT = 5

    customer_tab :all
    before_action { @active_tab = "orders" }

    # In BaseController, but needs to happen after loading the @submission
    skip_before_action :assert_sanger_enabled_for_facility
    load_and_authorize_resource except: :new
    before_action :load_and_authorize_on_new, only: :new
    before_action :prevent_after_purchase, except: [:show]
    before_action :assert_sanger_enabled_for_facility

    rescue_from CanCan::AccessDenied, with: :redirect_to_admin

    def self.permitted_sample_attributes
      @permitted_sample_attributes ||= [:id, :customer_sample_id, :_destroy, :primer_name]
    end

    def self.permitted_submission_params
      @permitted_submission_params ||= []
    end

    def new
      number_of_samples.times { @submission.create_prefilled_sample } if @submission.samples.none?
      render :edit
    end

    def show
    end

    def edit
    end

    def update
      if @submission.update(submission_params)
        redirect_to "#{params[:success_url]}&#{external_return_options.to_query}"
      else
        render :edit
      end
    end

    def create_sample
      sample = @submission.create_prefilled_sample
      render json: sample.slice(:id, :customer_sample_id)
    end

    def current_ability
      SangerSequencing::Ability.new(acting_user)
    end

    private

    def redirect_to_admin(error)
      if action_name == "show" && SangerSequencing::Ability.new(acting_user, current_facility).can?(:show, @submission)
        redirect_to facility_sanger_sequencing_admin_submission_path(current_facility, @submission)
      else
        render_403(error)
      end
    end

    def current_facility
      @current_facility ||= @submission.try(:facility)
    end

    def submission_params
      params.require(:sanger_sequencing_submission)
            .permit(self.class.permitted_submission_params,
                    samples_attributes: self.class.permitted_sample_attributes)
    end

    def external_return_options
      {
        quantity: @submission.samples.count,
        survey_edit_url: edit_sanger_sequencing_submission_url(@submission),
        survey_id: @submission.id,
        survey_url: sanger_sequencing_submission_url(@submission),
        referer: cart_path,
      }
    end

    def cart_path
      Rails.application.routes.url_helpers.order_path(@submission.order_id)
    end

    def load_and_authorize_on_new
      order_detail = ::OrderDetail.find(params[:receiver_id])
      @submission = SangerSequencing::Submission.where(order_detail_id: order_detail.id).first_or_create
      authorize! :create, @submission
    end

    def prevent_after_purchase
      raise ActiveRecord::RecordNotFound if @submission.purchased?
    end

    def number_of_samples
      Integer(params[:quantity])
    rescue ArgumentError
      5
    end

  end

end
