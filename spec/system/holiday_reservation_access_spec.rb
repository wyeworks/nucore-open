# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reserving an instrument on a holiday" do

  let(:user) { create(:user) }
  let!(:instrument) { create(:setup_instrument, restrict_holiday_access: true) }
  let(:facility) { instrument.facility }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { create(:instrument_price_policy, price_group: PriceGroup.base, product: instrument) }
  let!(:holiday) { Holiday.create(date: 2.days.from_now) }

  before do
    login_as user
    visit facility_path(facility)
  end

  context "as a member of an approved group" do
    let!(:product_access_group) { create(:product_access_group, allow_holiday_access: true, product: instrument) }
    let!(:product_user) { create(:product_user, user: user, product_access_group: product_access_group, product: instrument) }

    context "with user_based_price_groups_exclude_purchaser ff disabled (default)" do
      it "allows making a reservation" do
        click_link instrument.name
        select user.accounts.first.description, from: "Payment Source"
        fill_in "Reserve Start", with: 2.days.from_now
        click_button "Create"
        expect(page).to have_content("Reservation created successfully")
      end
    end

    context "with user_based_price_groups_exclude_purchaser enabled", :feature_setting => { user_based_price_groups_exclude_purchaser: true } do
      context "when account HAS price groups configured" do
        before do
          # With the FF enabled, account needs price groups
          create(:account_price_group_member, account:, price_group: PriceGroup.base)
          instrument.price_group_products.update_all(reservation_window: 7)
        end

        it "allows making a reservation" do
          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"
          fill_in "Reserve Start", with: 2.days.from_now
          click_button "Create"
          expect(page).to have_content("Reservation created successfully")
        end
      end

      context "when account has NO price groups configured" do
        before do
          AccountPriceGroupMember.where(account:).destroy_all
          instrument.price_group_products.update_all(reservation_window: 1)
        end

        it "fails with 'too far in advance' error when trying to reserve 2 days ahead" do
          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"
          fill_in "Reserve Start", with: 2.days.from_now
          click_button "Create"
          expect(page).to have_content("The reservation is too far in advance")
          expect(page).not_to have_content("Reservation created successfully")
        end

        it "allows reservation within the minimum window (1 day)" do
          click_link instrument.name
          select user.accounts.first.description, from: "Payment Source"
          fill_in "Reserve Start", with: 1.day.from_now
          click_button "Create"
          expect(page).to have_content("Reservation created successfully")
        end
      end
    end
  end

  context "as a member of a restricted group" do
    context "non-admin" do
      it "does NOT allow making a reservation" do
        click_link instrument.name
        select user.accounts.first.description, from: "Payment Source"
        fill_in "Reserve Start", with: 2.days.from_now
        click_button "Create"
        expect(page).to have_content("Reserve Start cannot be on a holiday because you do not have holiday access")
      end
    end

    context "as an admin" do
      let(:user) { create(:user, :administrator) }

      it "allows making a reservation" do
        click_link instrument.name
        select user.accounts.first.description, from: "Payment Source"
        fill_in "Reserve Start", with: 2.days.from_now
        click_button "Create"
        expect(page).to have_content("Reservation created successfully")
      end
    end
  end

end
