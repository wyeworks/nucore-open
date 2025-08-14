# frozen_string_literal: true

RSpec.shared_context "billing statements" do
  let(:account1) { create(:account, :with_account_owner) }
  let(:account2) { create(:account, :with_account_owner) }

  # Expects `facility` to be defined in the including context
  let(:statement1) { create(:statement, account: account1, facility:) }
  let(:statement2) { create(:statement, account: account2, facility:) }
end

RSpec.shared_context "billing statements with deposit numbers" do
  include_context "billing statements"

  # Expects `facility` to be defined in the including context
  let!(:order1) { create(:order, facility:, user: account1.owner_user, created_by_user: account1.owner_user) }
  let!(:order2) { create(:order, facility:, user: account2.owner_user, created_by_user: account2.owner_user) }
  let!(:product) { create(:setup_item, facility:) }

  let!(:order_detail1) do
    create(:order_detail,
           order: order1,
           product:,
           statement: statement1,
           deposit_number: "CHECK-001"
          )
  end

  let!(:order_detail2) do
    create(:order_detail,
           order: order2,
           product:,
           statement: statement2,
           deposit_number: "WIRE-002"
          )
  end

  let!(:order_detail_no_deposit) do
    create(:order_detail,
           order: order1,
           product:,
           statement: statement1,
           deposit_number: nil
          )
  end
end
