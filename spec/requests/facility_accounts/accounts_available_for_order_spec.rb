# frozen_string_literal: true

require "rails_helper"

RSpec.describe "listing the payment sources available for an order" do
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:customer) { create(:user) }
  let(:account) do
    create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: customer))
  end
  let!(:order) { create(:purchased_order, product: item, account: account, user: customer) }

  def get_available_accounts
    get accounts_available_for_order_facility_accounts_path(facility, format: :json),
        params: { order_id: order.id }
  end

  describe "as a user without any role" do
    let(:unprivileged_user) { create(:user) }

    before { login_as unprivileged_user }

    it "is forbidden" do
      get_available_accounts

      expect(response).to be_forbidden
    end

    it "does not disclose the account number" do
      get_available_accounts

      expect(response.body).not_to include(account.account_number)
    end
  end

  describe "as a facility director" do
    let(:director) { create(:user, :facility_director, facility: facility) }

    before { login_as director }

    it "returns the payment sources available for the order" do
      get_available_accounts

      expect(response).to be_successful
      expect(response.parsed_body.pluck("id")).to include(account.id)
    end
  end

  describe "as staff of another facility, while building a cross-core order" do
    let(:other_facility) { create(:setup_facility) }
    let(:staff) { create(:user, :staff, facility: other_facility) }

    before { login_as staff }

    it "returns the payment sources available for the order" do
      get_available_accounts

      expect(response).to be_successful
      expect(response.parsed_body.pluck("id")).to include(account.id)
    end
  end
end
