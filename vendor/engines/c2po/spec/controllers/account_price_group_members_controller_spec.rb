# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountPriceGroupMembersController do
  let(:facility) { create(:facility) }

  describe "search_results" do
    # Ignore validation errors, e.g. number format
    before { allow(AccountValidator::ValidatorFactory).to receive(:instance).and_return(AccountValidator::ValidatorDefault.new) }
    before { skip if facility_account_type.blank? }

    let(:partial_account_number) { build(:nufs_account).account_number[0..-4] }
    let(:price_group) { create(:price_group, facility: facility) }
    let(:global_account_type) { Account.config.global_account_types.first }
    let(:facility_account_type) { Account.config.facility_account_types.first }
    let!(:global_account) do
      create(
        global_account_type.underscore,
        :with_account_owner,
        account_number: "#{partial_account_number}234",
      )
    end
    let!(:facility_purchase_order) do
      create(
        facility_account_type.underscore,
        :with_account_owner,
        account_number: "#{partial_account_number}894",
        facility:,
      )
    end
    let!(:other_facility_purchase_order) do
      create(
        facility_account_type.underscore,
        :with_account_owner,
        account_number: "#{partial_account_number}542",
        facility: create(:facility),
      )
    end
    let(:user) { create(:user, :facility_administrator, facility:) }

    it "limits the results to global and the facility" do
      sign_in user

      get :search_results, params: { facility_id: facility.url_name, price_group_id: price_group.id, search_term: partial_account_number }
      expect(assigns[:accounts]).to contain_exactly(global_account, facility_purchase_order)
    end
  end
end
