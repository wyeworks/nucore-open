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

  before do
    account1.update!(account_number: "12345-CHECK", description: "Research Lab A")
    account2.update!(account_number: "54321-WIRE", description: "Chemistry Dept")
  end
end
