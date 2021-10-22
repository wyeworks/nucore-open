# frozen_string_literal: true

# For having more conveniently named route helpers so you don't always
# have to include current_facility, etc.
module RoutesHelper

  def manage_order_detail_path(order_detail)
    manage_facility_order_order_detail_path(order_detail.facility, order_detail.order, order_detail)
  end

  def admin_order_detail_path(action, order_detail)
    send("#{action}_facility_order_order_detail_path", order_detail.facility, order_detail.order, order_detail)
  end

  def sign_out_user_path
    # Allow for custom logout paths from saml or other authenticable options
    strategy = warden.session(:user)[:strategy]&.to_sym
    # facility_id will cause the user to be redirected to the facility's home page after logout
    [:destroy, strategy, :user_session, facility_id: current_facility&.url_name].compact
  end

  def statement_path(statement)
    facility_account_statement_path(statement.facility, statement.account_id, statement, format: :pdf)
  end

  def product_file_path(file)
    [
      file.product.facility,
      file.product,
      :download_product_file,
      file_type: file.file_type,
      id: file,
    ]
  end

  def stored_file_path(file)
    public_send("order_order_detail_#{file.file_type.pluralize}_path",
                file.order_detail.order,
                file.order_detail,
                file)
  end

  def facility_sample_result_path(sample_result_file)
    sample_results_facility_order_order_detail_path(
      sample_result_file.order_detail.facility,
      sample_result_file.order_detail.order,
      sample_result_file.order_detail,
      sample_result_file,
    )
  end

  def facility_template_result_path(template_result_file)
    template_results_facility_order_order_detail_path(
      template_result_file.order_detail.facility,
      template_result_file.order_detail.order,
      template_result_file.order_detail,
      template_result_file,
    )
  end

  def order_detail_first_template_result_path(order_detail)
    stored_file_path(order_detail.stored_files.template_result.first)
  end

end
