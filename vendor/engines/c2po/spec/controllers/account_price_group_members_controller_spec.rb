# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountPriceGroupMembersController do
  let(:facility) { create(:facility) }

  describe "search_results" do
    # Ignore validation errors, e.g. number format
    before { allow(AccountValidator::ValidatorFactory).to receive(:instance).and_return(AccountValidator::ValidatorDefault.new) }

    let(:partial_account_number) { build(:nufs_account).account_number[0..-5] }
    let(:price_group) { create(:price_group, facility: facility) }
    let!(:global_account) { create(:nufs_account, :with_account_owner, account_number: "#{partial_account_number}1234") }
    let!(:facility_purchase_order) { create(:purchase_order_account, :with_account_owner, account_number: "#{partial_account_number}7894", facility: facility) }
    let!(:other_facility_purchase_order) { create(:purchase_order_account, :with_account_owner, account_number: "#{partial_account_number}6542", facility: create(:facility)) }

    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it "limits the results to global and the facility" do
      sign_in user

      get :search_results, params: { facility_id: facility.url_name, price_group_id: price_group.id, search_term: partial_account_number }
      expect(assigns[:accounts]).to contain_exactly(global_account, facility_purchase_order)
    end
  end
end
