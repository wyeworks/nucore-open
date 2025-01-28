# frozen_string_literal: true

module SangerSequencing

  module Admin

    class PrimersController < AdminController
      admin_tab :all
      layout "two_column"
      before_action { @active_tab = "manage_primers" }
      authorize_sanger_resource class: "SangerSequencing::Primer"

      def index
      end

      def edit
      end

      def update
        if current_facility.update(primers_params)
          redirect_to facility_sanger_sequencing_admin_primers_path(current_facility)
        else
          render :edit
        end
      end

      private

      def primers_params
        params.require(:facility).permit(
          sanger_sequencing_primers_attributes: %i[id _destroy name]
        )
      end

    end

  end

end
