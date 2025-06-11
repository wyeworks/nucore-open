# frozen_string_literal: true

require "rails_helper"

RSpec.describe(
  "Account Price Group tab",
  feature_setting: { show_account_price_groups_tab: true }
) do
  let(:facility) { Facility.cross_facility }
  let(:account) { create(:account, :with_account_owner) }

  describe "show" do
    let(:facility) { create(:setup_facility) }
    let(:internal_price_group) do
      create(:price_group, facility:, is_internal: true)
    end
    let(:global_price_group) { PriceGroup.globals.first }
    let(:visit_page) do
      visit facility_account_price_groups_path(facility, account)
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
      visit_page

      expect(page.current_path).to eq(new_user_session_path)
    end

    context "with non authorized user", :disable_requests_local do
      before { login_as create(:user) }

      it "shows forbidden page" do
        visit_page

        expect(page).to have_content("Sorry, you don't have permission to access this page")
      end
    end

    context "with authorized user" do
      let(:other_price_group) do
        PriceGroup.where.not(id: account.price_groups.pluck(:id))
      end

      before { login_as create(:user, :administrator) }

      it "shows account price groups" do
        visit_page

        within("table.table") do
          expect(page).to have_content(global_price_group.name)
          expect(page).to have_content(internal_price_group.name)
          expect(page).not_to have_content(other_price_group.name)
        end
      end
    end
  end

  describe "edit/update" do
    let(:unselected_price_groups) do
      PriceGroup.where.not(
        id: account.price_groups_relation.pluck(:id),
      )
    end
    let(:visit_page) do
      visit edit_facility_account_price_groups_path(facility, account)
    end

    context "with non authorized user" do
      before do
        login_as(create(:user, :account_manager))
      end

      it "is not allow to access edit page", :disable_requests_local do
        visit edit_facility_account_price_groups_path(facility, account)

        expect(page).to have_content("Sorry, you don't have permission to access this page")
      end

    end

    context "with authorized user" do
      before { login_as create(:user, :administrator) }
      before { account.price_groups_relation << PriceGroup.globals.first }

      it "allows admins to update price groups" do
        visit_page

        expect(page).to have_select(
          "account[price_groups_relation_ids][]",
          options: PriceGroup.all.map(&:name),
          selected: account.price_groups_relation.map(&:name),
        )

        unselected_price_groups.each do |price_group|
          select(
            price_group.name,
            from: "account[price_groups_relation_ids][]",
          )
        end

        click_button "Save"

        expect(page).to have_content(
          "Price Groups assigned successfully",
        )

        expect(account.reload.price_groups_relation.count).to(
          eq(PriceGroup.count),
        )
      end
    end
  end

  context "when the ff is disabled", feature_setting: { show_account_price_groups_tab: false } do
    it "does not show the price groups tab" do
      login_as create(:user, :administrator)

      visit facility_account_path(facility, account)

      expect(page).to have_content(account.description)
      expect(page).not_to have_content("Price Groups")
    end
  end
end
