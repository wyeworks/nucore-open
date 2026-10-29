# frozen_string_literal: true

require "rails_helper"
require "account_builder_shared_examples"

RSpec.describe CreditCardAccountBuilder, type: :service do
  let(:options) do
    {
      account_params_key: "credit_card_account",
      account_type: "CreditCardAccount",
      current_user: user,
      facility:,
      owner_user: user,
      params:,
    }
  end
  let(:params) do
    ActionController::Parameters.new(
      credit_card_account: {
        name_on_card: "First Last",
        expiration_month: 1.year.from_now.month,
        expiration_year: 1.year.from_now.year,
        description: "A Credit Card",
        affiliate_id: affiliate.try(:id),
        affiliate_other:,
        remittance_information: "Bill To goes here",
      },
    )
  end

  it_behaves_like "AccountBuilder#build"
end
