# frozen_string_literal: true

RSpec.shared_context "billing statements" do
  let(:account1) { create(:account, :with_account_owner) }
  let(:account2) { create(:account, :with_account_owner) }

  # Expects `facility` to be defined in the including context
  let(:statement1) { create(:statement, account: account1, facility:) }
  let(:statement2) { create(:statement, account: account2, facility:) }
end

RSpec.shared_context "billing statements with payments and creditcard" do
  include_context "billing statements"

  let(:paid_by_user) { create(:user) }

  let!(:payment1) do
    create(
      :payment,
      statement: statement1,
      account: account1,
      source: "check",
      amount: 100.0,
      processing_fee: 0.0,
      paid_by: paid_by_user,
    )
  end

  let!(:payment2) do
    create(
      :payment,
      statement: statement2,
      account: account2,
      source: "check",
      amount: 200.0,
      processing_fee: 0.0,
      paid_by: paid_by_user,
    )
  end

  before do
    Payment.valid_sources << :creditcard unless Payment.valid_sources.include?(:creditcard)
    payment2.update!(source: "creditcard")
  end

  after do
    Payment.valid_sources.delete(:creditcard)
  end
end
