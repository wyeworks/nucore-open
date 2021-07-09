# frozen_string_literal: true

class ProductUserImportsController < ApplicationController

  include ActionView::Helpers::TextHelper

  admin_tab     :all
  before_action :authenticate_user!
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product

  def create
    begin
      import = create_product_user_import!
      import.process_upload!
      if import.succeeded?
        flash[:notice] = import_success_alert(import)
      else
        flash[:error] = import_failed_alert(import)
      end
    rescue => e
      import_exception_alert(e)
    end

    redirect_to url_for([current_facility, @product, :users])
  end

  private

  def create_params
    params.require(:product_user_import).permit(:file)
  end

  def create_product_user_import!
    raise "Please upload a valid import file" if file.blank?

    ProductUserImport.create!(
      create_params.merge(
        creator: session_user,
        product: @product,
      )
    )
  end

  def import_exception_alert(exception)
    Rails.logger.error "#{exception.message}\n#{exception.backtrace.join("\n")}"
    flash[:error] = text("controllers.product_user_imports.create.error", error: exception.message)

  end

  def import_success_alert(import)
    if import.skipped.present?
      html("controllers.product_user_imports.create.success", count: import.successes.count, added: import.successes.join) +
      html("controllers.product_user_imports.create.skips", skipped: import.skipped.join)
    else
      html("controllers.product_user_imports.create.success", count: import.successes.count, added: import.successes.join)
    end
  end

  def import_failed_alert(import)
    html("controllers.product_user_imports.create.failure", count: import.failures.count, errors: import.failures.join)
  end

  def file
    params.fetch(:product_user_import, {}).fetch(:file, nil)
  end

  def init_product
    @product = current_facility.products.find_by!(url_name: params[:product_id])
  end

end
