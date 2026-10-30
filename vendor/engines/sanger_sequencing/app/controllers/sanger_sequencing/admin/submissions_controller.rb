# frozen_string_literal: true

module SangerSequencing
  module Admin
    class SubmissionsController < AdminController
      admin_tab :all
      layout "two_column"
      before_action { @active_tab = "admin_sanger_sequencing" }

      before_action :load_submission, only: :show
      authorize_sanger_resource class: "SangerSequencing::Submission"

      def index
        @submissions = Submission.purchased.for_facility(current_facility).paginate(page: params[:page])
      end

      def show
        render layout: false if modal?
      end

      private

      def load_submission
        @submission = Submission.purchased.for_facility(current_facility).find(params[:id])
      end

      def modal?
        request.xhr?
      end
      helper_method :modal?
    end
  end
end
