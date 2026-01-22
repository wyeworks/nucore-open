# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Managing Price Groups", :aggregate_failures do
  let(:facility) { create(:facility) }

  describe "create" do
    describe "as a facility admin", feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:user) { create(:user, :facility_director, facility:) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
        click_link "Add Price Group"
        fill_in "Name", with: "New Price Group"
        check "Is Internal?"
      end

      it "creates a price group and brings you back to the index" do
        expect { click_button "Create" }.to change(PriceGroup, :count).by(1)
        expect(current_path).to eq(accounts_facility_price_group_path(facility, PriceGroup.reorder(:id).last))
        log_event = LogEvent.find_by(loggable: PriceGroup.reorder(:id).last, event_type: :create)
        expect(log_event).to be_present
      end
    end

    describe "as a facility senior staff" do
      let(:user) { create(:user, :senior_staff, facility:) }

      before do
        login_as user
      end

      it_behaves_like "raises specified error", -> { visit new_facility_price_group_path(facility) }, CanCan::AccessDenied
    end
  end

  describe "manage users of a price group" do
    describe "as a facility admin", feature_setting: { user_based_price_groups: true, facility_directors_can_manage_price_groups: true } do
      let(:user) { create(:user, :facility_director, facility:) }
      let(:user2) { create(:user) }
      let!(:price_group) { create(:price_group, facility:) }

      before do
        login_as user
        visit users_facility_price_group_path(facility, price_group)
      end

      it "is accessible", :js do
        skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
        expect(page).to be_axe_clean
      end

      context "add a user to the price group" do
        it "creates a price group member and logs the new price group member" do
          click_link "Add User"
          fill_in "search_term", with: user2.name
          click_button "Search"
          expect { click_link user2.last_first_name }.to change(PriceGroupMember, :count).by(1)
          log_event = LogEvent.find_by(loggable: PriceGroupMember.reorder(:id).last, event_type: :create)
          expect(log_event).to be_present
        end
      end

      context "remove a user from the price group" do
        it "soft delete the price group memeber and logs it" do
          user_price_group_member = create(:user_price_group_member, price_group: price_group, user: user)
          visit users_facility_price_group_path(facility, price_group)
          expect { click_link "Remove" }.to change(PriceGroupMember, :count).by(-1)
          log_event = LogEvent.find_by(loggable: user_price_group_member, event_type: :delete)
          expect(log_event).to be_present
        end
      end

      context "search for a user", :js do
        let(:user_searchable) { create(:user, first_name: "John", last_name: "Doe", username: "jdoe") }
        let(:user_not_found) { create(:user, first_name: "Jane", last_name: "Holmes", username: "jholmes") }

        before do
          create(:user_price_group_member, price_group: price_group, user: user_not_found)
          create(:user_price_group_member, price_group: price_group, user: user_searchable)
          visit users_facility_price_group_path(facility, price_group)
        end

        it "searches for users by first name" do
          fill_in "price_group_user_search", with: "John"
          click_button "Search"
          wait_for_ajax
          expect(page).to have_content(user_searchable.name)
          expect(page).to_not have_content(user_not_found.name)
          expect(page).to_not have_content(user2.name)
        end

        it "searches for users by last name" do
          fill_in "price_group_user_search", with: "Doe"
          click_button "Search"
          wait_for_ajax
          expect(page).to have_content(user_searchable.name)
          expect(page).to_not have_content(user_not_found.name)
          expect(page).to_not have_content(user2.name)
        end

        it "searches for users by username" do
          fill_in "price_group_user_search", with: "jdoe"
          click_button "Search"
          wait_for_ajax
          expect(page).to have_content(user_searchable.name)
          expect(page).to_not have_content(user_not_found.name)
          expect(page).to_not have_content(user2.name)
        end

        it "searches for users by first name (case insensitive)" do
          fill_in "price_group_user_search", with: "john"
          click_button "Search"
          wait_for_ajax
          expect(page).to have_content(user_searchable.name)
          expect(page).to_not have_content(user_not_found.name)
          expect(page).to_not have_content(user2.name)
        end
      end
    end
  end

  describe "destroy" do
    describe "as a facility admin", feature_setting: { facility_directors_can_manage_price_groups: true } do
      let(:user) { create(:user, :facility_director, facility:) }
      let!(:price_group) { create(:price_group, facility:) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
      end

      it "deletes a price group and brings you back to the index" do
        expect { click_link "Remove" }.to change(PriceGroup, :count).by(-1)
        expect(current_path).to eq(facility_price_groups_path(facility))
        log_event = LogEvent.find_by(loggable: price_group, event_type: :delete)
        expect(log_event).to be_present
      end

      it "is accessible", :js do
        skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
        expect(page).to be_axe_clean
      end
    end

    describe "as a facility senior staff" do
      let(:user) { create(:user, :senior_staff, facility:) }
      let!(:price_group) { create(:price_group, facility:) }

      before do
        login_as user
        visit facility_price_groups_path(facility)
      end

      it "does not have a remove link present" do
        expect(page).not_to have_link("Remove")
      end
    end
  end

  describe "searching to add price group member", js: true do
    let(:user) { create(:user, :facility_director, facility:) }
    let(:price_group) { create(:price_group, facility_id: facility.id ) }
    let!(:account1) { create(:account, :with_account_owner, account_number: "135711", description: "first account", facilities: [facility], owner: user) }
    let!(:account2) { create(:account, :with_account_owner, account_number: "246810", description: "second account", facilities: [facility], owner: user) }

    before do
      allow(Account.config).to receive(:facility_account_types).and_return(["Account"])
      login_as user
      visit new_facility_price_group_account_price_group_member_path(facility, price_group)
    end

    it "searches for accounts by partial description" do
      fill_in "search_term", with: account1.description[0,5]
      click_button "Search"
      expect(page).to have_content(account1.description)
      expect(page).to_not have_content(account2.description)
    end

    it "searches for accounts by partial account number" do
      fill_in "search_term", with: account2.account_number[1,3]
      click_button "Search"
      expect(page).to have_content(account2.description)
      expect(page).to_not have_content(account1.description)
    end

    it "is accessible" do
      skip "Accessibility tests temporarily disabled during Bootstrap 2->3 migration"
      expect(page).to be_axe_clean
    end
  end

  describe "external subsidy price groups", feature_setting: { external_price_group_subsidies: true, facility_directors_can_manage_price_groups: true } do
    let(:user) { create(:user, :facility_director, facility:) }
    let!(:external_base) { create(:price_group, :global_external, name: "External Rate 1") }

    before do
      login_as user
    end

    describe "creating an external subsidy" do
      it "shows the subsidy dropdown for external groups" do
        visit new_facility_price_group_path(facility)
        expect(page).to have_content("Make this price group a subsidy:")
        expect(page).to have_select("price_group_parent_price_group_id")
      end

      it "creates an external price group as a subsidy" do
        visit new_facility_price_group_path(facility)
        fill_in "Name", with: "Subsidized External"
        uncheck "Is Internal?" if has_checked_field?("Is Internal?")
        select "External Rate 1", from: "price_group_parent_price_group_id"

        expect { click_button "Create" }.to change(PriceGroup, :count).by(1)

        new_group = PriceGroup.find_by(name: "Subsidized External")
        expect(new_group.parent_price_group).to eq(external_base)
        expect(new_group).to be_external_subsidy
      end
    end

    describe "viewing the index" do
      let!(:subsidy_group) { create(:price_group, facility:, is_internal: false, name: "Subsidized Group", parent_price_group: external_base) }

      it "shows subsidies with visual indicator" do
        visit facility_price_groups_path(facility)
        expect(page).to have_content("↳")
        expect(page).to have_content("(subsidy of External Rate 1)")
      end

      it "orders subsidies below their parent group" do
        visit facility_price_groups_path(facility)
        page_content = page.body
        external_base_position = page_content.index("External Rate 1")
        subsidy_position = page_content.index("Subsidized Group")
        expect(subsidy_position).to be > external_base_position
      end
    end
  end

  # TODO: Move tests out of price_groups_controller_spec.rb
end
