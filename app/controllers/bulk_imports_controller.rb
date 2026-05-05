# frozen_string_literal: true

class BulkImportsController < ApplicationController
  load_and_authorize_resource

  layout "two_column"
  before_action { @active_tab = "global_settings" }

  def index
    @bulk_imports =
      @bulk_imports
      .by_date
      .includes(:created_by)
      .includes_file
      .paginate(page: params[:page])
  end

  def show
  end

  def new
  end

  def help
    @importer_class = BulkImport.import_classes[params[:import_type]]

    render partial: "bulk_imports/help"
  end

  def template
    importer_class = BulkImport.import_classes[params[:import_type]]

    if importer_class
      respond_to do |format|
        format.csv do
          filename = "#{params[:import_type]}_template.csv"
          render csv: importer_class.csv_template, filename:
        end
      end
    else
      render plain: "Invalid type", status: :bad_request
    end
  end

  def create
    @bulk_import = BulkImport.new(create_params)

    if create_params[:file].blank?
      flash.now[:error] = t(".file_blank")

      return render(
        :new,
        status: :bad_request,
      )
    end

    if @bulk_import.save
      BulkImportJob.perform_later(@bulk_import)

      redirect_to bulk_imports_path, notice: t(".success")
    else
      render :new, status: :bad_request
    end
  end

  private

  def create_params
    params.require(:bulk_import).permit(
      :import_type,
      :file,
    ).merge(created_by: current_user)
  end
end
