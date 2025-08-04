# frozen_string_literal: true

module BulkEmail

  class JobsController < ApplicationController

    admin_tab :all
    layout "two_column"

    before_action { @active_tab = "admin_users" }
    before_action :check_acting_as
    before_action :init_current_facility
    before_action { authorize! :send_bulk_emails, current_facility }

    def index
      @bulk_email_jobs = BulkEmail::Job
                         .where(facility: current_facility)
                         .order(created_at: :desc)
                         .paginate(page: params[:page])
    end

    def show
      job = BulkEmail::Job.where(facility: current_facility).find(params[:id])
      @bulk_email_job = BulkEmail::JobDecorator.new(job)
    end

  end

end
