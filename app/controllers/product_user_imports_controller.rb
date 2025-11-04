# frozen_string_literal: true

class ProductUserImportsController < ApplicationController

  include ActionView::Helpers::TextHelper

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :init_product

  def create
    begin
      import = create_product_user_import!
      import.process_upload!
      if !import.failed?
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
    params.expect(product_user_import: [:file])
  end

  def create_product_user_import!
    raise "Please upload a valid import file" if file.blank?

    ProductUserImport.new(
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
      html_text = html("controllers.product_user_imports.create.success", count: import.successes.count)

      html_text += if import.skipped.count < 30
                     html("controllers.product_user_imports.create.skips", skipped: import.skipped.join)
                   else
                     html("controllers.product_user_imports.create.skips_number", count: import.skipped.count)
                   end
      html_text
    else
      html("controllers.product_user_imports.create.success", count: import.successes.count)
    end
  end

  def import_failed_alert(import)
    if import.failures.count < 30
      html("controllers.product_user_imports.create.failure", count: import.failures.count, errors: import.failures.join)
    else
      html("controllers.product_user_imports.create.failure_count", count: import.failures.count, support_email: Settings.support_email)
    end
  end

  def file
    params.fetch(:product_user_import, {}).fetch(:file, nil)
  end

  def init_product
    @product = current_facility.products.find_by!(url_name: params[:product_id])
  end

end
