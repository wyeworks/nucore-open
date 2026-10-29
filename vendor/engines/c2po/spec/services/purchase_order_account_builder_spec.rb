# frozen_string_literal: true

require "rails_helper"
require "account_builder_shared_examples"

RSpec.describe PurchaseOrderAccountBuilder, type: :service do
  let(:options) do
    {
      account_params_key: "purchase_order_account",
      account_type: "PurchaseOrderAccount",
      current_user: user,
      facility:,
      owner_user: user,
      params:,
    }
  end
  let(:params) do
    ActionController::Parameters.new(
      purchase_order_account: {
        account_number: "PO1234567",
        description: "A Purchase Order",
        affiliate_id: affiliate.try(:id),
        affiliate_other:,
        remittance_information: "Bill To goes here",
        formatted_expires_at: I18n.l(1.year.from_now.to_date, format: :usa),
        outside_contact_info: "800 588-2300",
      },
    )
  end

  it_behaves_like "AccountBuilder#build"
end
