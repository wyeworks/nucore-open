# frozen_string_literal: true

module SangerSequencing

  module Admin

    class PrimersController < AdminController
      def index
      end

      def edit
      end

      def update
        if current_facility.update(primers_params, touch: false)
          redirect_to :index
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
