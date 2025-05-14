# frozen_string_literal: true

class OrderImportsController < ApplicationController

  include ActionView::Helpers::TextHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility

  authorize_resource

  def initialize
    @active_tab = "admin_orders"
    super
  end

  def new
    @order_import = OrderImport.new
    @order_imports = get_order_imports.paginate(page: params[:page])
  end

  def create
    begin
      process_order_import!
    rescue => e
      import_exception_alert(e)
    end

    redirect_to new_facility_order_import_path
  end

  def error_report
    if order_import.error_file_present?
      redirect_to order_import.error_file_download_url
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  private

  def create_params
    params.require(:order_import).permit(:upload_file, :fail_on_error, :send_receipts)
  end

  def create_order_import!
    OrderImport.transaction do
      order_import = OrderImport.create!(
        create_params.merge(
          created_by: session_user.id,
          upload_file: stored_file,
          facility: @current_facility,
        ),
      )
      LogEvent.log(
        order_import,
        :created,
        session_user,
      )

      order_import
    end
  end

  def import_exception_alert(exception)
    Rails.logger.error "#{exception.message}\n#{exception.backtrace.join("\n")}"
    flash[:error] = import_exception_message(exception)
  end

  def import_exception_message(exception)
    I18n.t("controllers.order_imports.create.error", error: exception.message)
  end

  def get_order_imports
    @current_facility.order_imports.order("created_at DESC")
  end

  def order_import
    @order_import ||= current_facility.order_imports.find(params[:id])
  end

  def process_order_import!
    raise "Please upload a valid import file" if upload_file.blank?
    @order_import = create_order_import!
    OrderImportJob.perform_later(@order_import, report_recipient)
    flash[:notice] = t("controllers.order_imports.create.job_is_queued", email: report_recipient)
  end

  def report_recipient
    @report_recipient ||= params[:report_recipient].presence || @order_import.creator.email
  end

  def stored_file
    StoredFile.new(
      name: upload_file.try(:original_filename),
      file: upload_file,
      file_type: "import_upload",
      created_by: session_user.id,
    )
  end

  def upload_file
    @upload_file ||= create_params.delete(:upload_file)
  end

end
