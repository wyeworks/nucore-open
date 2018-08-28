# frozen_string_literal: true

module SangerSequencing

  module Admin

    class BatchesController < AdminController

      admin_tab :all
      layout "two_column", only: [:index]
      before_action { @active_tab = "admin_sanger_sequencing" }
      before_action :load_batch_form, only: [:new, :create]
      before_action :load_batch, only: [:well_plate, :show, :destroy, :upload]
      before_action :validate_product_group, only: [:index, :new, :create]
      authorize_sanger_resource class: "SangerSequencing::Batch"

      def index
        @batches = Batch.for_facility(current_facility)
                        .order(created_at: :desc)
                        .for_product_group(params[:group])
                        .paginate(page: params[:page])
      end

      def new
        @submissions = Submission.ready_for_batch
                                 .includes(:samples, order_detail: :product)
                                 .for_facility(current_facility)
                                 .for_product_group(params[:group])
        @builder_config = WellPlateConfiguration.find(params[:group])
      end

      def create
        # Whitelisting should happen in the form object
        if @batch.update_attributes(params[:batch].merge(created_by: current_user, facility: current_facility))
          redirect_to [current_facility, :sanger_sequencing, :admin, :batches, group: @batch.group], notice: text("create.success")
        else
          @submissions = Submission.ready_for_batch.for_facility(current_facility)
          flash.now[:alert] = @batch.errors.map { |_k, msg| msg }.to_sentence
          render :new
        end
      end

      def show
        @submissions = @batch.submissions.purchased # purchased to get the same sorting
      end

      def well_plate
        index = params[:well_plate_index].to_i
        @well_plate = @batch.well_plates[index - 1]
        raise ActiveRecord::RecordNotFound unless @well_plate

        respond_to do |format|
          format.csv do
            render csv: WellPlatePresenter.new(@well_plate, @batch.group), filename: "well_plate_#{@batch.id}_#{index}"
          end
        end
      end

      def destroy
        @batch.destroy
        redirect_to facility_sanger_sequencing_admin_batches_path(group: @batch.group), notice: text("destroy.success")
      end

      def upload
        saver = SampleResultFileSaver.new(@batch, current_user, params)

        response = if saver.save
                     { success: true }
                   else
                     { success: false, error: saver.errors.map { |_k, msg| msg }.to_sentence }
        end

        respond_to do |format|
          format.json { render json: response }
        end
      end

      class UploadError < StandardError
      end

      private

      def validate_product_group
        @product_group = params[:group].presence
        raise ActiveRecord::RecordNotFound unless @product_group.blank? || ProductGroup::GROUPS.include?(@product_group)
      end

      def load_batch
        @batch = Batch.for_facility(current_facility).find(params[:id])
      end

      def load_batch_form
        @batch = BatchForm.new(SangerSequencing::Batch.new(group: params[:group]))
      end

    end

  end

end
