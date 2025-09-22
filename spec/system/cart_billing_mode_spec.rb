# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding products with different billing modes to cart" do
  let(:facility) { create(:setup_facility) }
  let(:nonbillable_item) { create(:setup_item, facility:, billing_mode: "Nonbillable") }
  let(:default_item) { create(:setup_item, facility:, billing_mode: "Default") }
  let(:skip_review_item) { create(:setup_item, facility:, billing_mode: "Skip Review") }

  let(:internal_account) { create(:purchase_order_account, :with_account_owner, facility:) }
  let(:external_account) { create(:purchase_order_account, :with_account_owner, owner: external_user, facility:) }

  let(:internal_user) { internal_account.owner.user }
  let(:external_user) { create(:user, :external) }

  before(:each) do
    create(:account_user, :purchaser, account: internal_account, user: external_user)
    create(:account_user, :purchaser, account: external_account, user: internal_user)
  end

  ### SHARED EXAMPLES ###
  shared_examples "user with no accounts" do
    before(:each) do
      logged_in_user.account_users.each(&:destroy)
      login_as logged_in_user
    end

    it "allows a user without any accounts to add a Nonbillable product to cart" do
      visit facility_item_path(facility, nonbillable_item)
      click_on "Add to cart"
      expect(page).to have_content(nonbillable_item.name)
    end

    it "does not allow a user without any accounts to add a Skip Review product to cart" do
      visit facility_item_path(facility, skip_review_item)

      if SettingsHelper.feature_on?(:user_based_price_groups) && !SettingsHelper.feature_on?(:user_based_price_groups_exclude_purchaser)
        expect(page).to have_content("Sorry, but we could not find a valid payment source that you can use to purchase this")
      else
        expect(page).to have_content("No price groups found for this purchase")
      end
    end

    it "does not allow a user without any accounts to add a Default product to cart" do
      visit facility_item_path(facility, default_item)
      expect(page).to have_content("No price groups found for this purchase")
    end
  end

  shared_examples "adding items to the cart" do
    before(:each) do
      # The setup_item factory creates a price_policy
      # for a facility-based price group.
      # This allows purchasing the default_item
      # with internal_account or external_account.
      create(:item_price_policy, price_group: PriceGroup.base, product: default_item)
      create(:item_price_policy, price_group: PriceGroup.external, product: default_item)
      login_as logged_in_user
    end

    context "when a Nonbillable product is added first" do
      before do
        visit facility_item_path(facility, nonbillable_item)
        click_on "Add to cart"
      end

      it "can add another Nonbillable product" do
        expect(page).to have_content(nonbillable_item.name)
        visit facility_item_path(facility, nonbillable_item)
        click_on "Add to cart"
        expect(page).to have_content(nonbillable_item.name).twice
      end

      it "cannot add Skip Review item to cart" do
        visit facility_item_path(facility, skip_review_item)
        click_on "Add to cart"
        expect(page).to have_content("#{skip_review_item.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
      end

      it "cannot add a Default billing mode product" do
        visit facility_item_path(facility, default_item)
        click_on "Add to cart"
        expect(page).to have_content("#{default_item.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
      end
    end

    context "when a Skip Review product is added first" do
      before do
        visit facility_item_path(facility, skip_review_item)
        click_on "Add to cart"
        choose account_used.to_s
        click_button "Continue"
      end

      it "can add another Skip Review item to cart" do
        expect(page).to have_content(skip_review_item.name)
        visit facility_item_path(facility, skip_review_item)
        click_on "Add to cart"
        expect(page).to have_content(skip_review_item.name).twice
      end

      it "can add a Nonbillable product" do
        visit facility_item_path(facility, nonbillable_item)
        click_on "Add to cart"
        expect(page).to have_content(nonbillable_item.name)
      end

      it "can add Default item to cart" do
        visit facility_item_path(facility, default_item)
        click_on "Add to cart"
        expect(page).to have_content(default_item.name)
      end
    end

    context "when a Default product is added first" do
      before do
        visit facility_item_path(facility, default_item)
        click_on "Add to cart"
        choose account_used.to_s
        click_button "Continue"
      end

      it "can add another Default product" do
        expect(page).to have_content(default_item.name)
        visit facility_item_path(facility, default_item)
        click_on "Add to cart"
        expect(page).to have_content(default_item.name).twice
      end

      it "can add a Skip Review item to cart" do
        visit facility_item_path(facility, skip_review_item)
        click_on "Add to cart"
        expect(page).to have_content(skip_review_item.name)
      end

      it "can add a Nonbillable product" do
        visit facility_item_path(facility, nonbillable_item)
        click_on "Add to cart"
        expect(page).to have_content(default_item.name)
        expect(page).to have_content(nonbillable_item.name)
        expect(page).not_to have_content("#{nonbillable_item.name} cannot be added to your cart because it's billing mode does not match the current products in the cart; please clear your cart or place a separate order.")
      end
    end
  end

  ### SPEC CONTEXTS ###
  context "with user-based price groups disabled", feature_setting: { user_based_price_groups: false } do
    context "when a user has no price groups (or no account with price groups)" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { internal_user }
      end
    end

    context "with an external user that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { external_user }
      end
    end
  end

  context "with user-based price groups enabled", feature_setting: { user_based_price_groups: true } do
    context "with an internal that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { internal_user }
      end
    end

    context "with an external user that has no account" do
      it_behaves_like "user with no accounts" do
        let(:logged_in_user) { external_user }
      end
    end

    context "internal user and internal account" do
      it_behaves_like "adding items to the cart" do
        let(:logged_in_user) { internal_user }
        let(:account_used) { internal_account }
      end
    end

    context "internal user and external account" do
      it_behaves_like "adding items to the cart" do
        let(:logged_in_user) { internal_user }
        let(:account_used) { external_account }
      end
    end

    context "external user and external account" do
      it_behaves_like "adding items to the cart" do
        let(:logged_in_user) { external_user }
        let(:account_used) { external_account }
      end
    end

    context "external user and internal account" do
      it_behaves_like "adding items to the cart" do
        let(:logged_in_user) { external_user }
        let(:account_used) { internal_account }
      end
    end
  end
end
