# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account Price Group tab" do
  let(:account) { create(:account, :with_account_owner) }

  describe "show" do
    let(:facility) { create(:setup_facility) }
    let(:internal_price_group) do
      create(:price_group, facility:, is_internal: true)
    end
    let(:global_price_group) { PriceGroup.globals.first }
    let(:action) do
      lambda do
        visit facility_account_price_groups_path(Facility.cross_facility, account)
      end
    end

    before do
      AccountPriceGroupMember.create(
        price_group: internal_price_group,
        account:
      )
      AccountPriceGroupMember.create(
        price_group: global_price_group,
        account:
      )
    end

    it "requires login" do
      action.call

      expect(page.current_path).to eq(new_user_session_path)
    end

    context "with non authorized user", :disable_requests_local do
      before { login_as create(:user) }

      it "shows forbidden page" do
        action.call

        expect(page).to have_content("Sorry, you don't have permission to access this page")
      end
    end

    context "with authorized user" do
      let(:other_price_group) do
        PriceGroup.where.not(id: account.price_groups.pluck(:id))
      end

      before { login_as create(:user, :administrator) }

      it "shows account price groups" do
        action.call

        within("table.table") do
          expect(page).to have_content(global_price_group.name)
          expect(page).to have_content(internal_price_group.name)
          expect(page).not_to have_content(other_price_group.name)
        end
      end
    end
  end
end
