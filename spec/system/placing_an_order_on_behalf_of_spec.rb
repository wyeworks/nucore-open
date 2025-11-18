# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Placing an order on behalf of" do
  describe "an item order" do
    let!(:product) { create(:setup_item) }
    let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
    let(:facility) { product.facility }
    let!(:price_policy) do
      create(:item_price_policy,
             price_group: PriceGroup.base,
             product:,
             unit_cost: 33.25,
             start_date: 6.days.ago.beginning_of_day)
    end
    let!(:account_price_group_member) do
      create(:account_price_group_member, account:, price_group: price_policy.price_group)
    end
    let(:user) { create(:user) }
    let(:facility_admin) { create(:user, :facility_administrator, facility:) }

    before do
      login_as facility_admin
      visit facility_users_path(facility)
      fill_in "search_term", with: user.email
      click_button "Search"
      click_link "Order For"
    end

    it "can place an order" do
      visit facility_path(facility)
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"

      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
      expect(page).to have_content "Ordered For\n#{user.full_name}"
      expect(page).to have_content "$33.25"
    end

    describe "trying to purchase after updating the quantity" do
      before do
        click_link product.name
        click_link "Add to cart"
        choose account.to_s
        click_button "Continue"
        fill_in "Note", with: "A note"
        fill_in "Reference ID", with: "Ref123"
        fill_in "Quantity", with: "45"
        click_button "Purchase"
      end

      it "returns to the cart, and the fields are properly updated" do
        expect(page).to have_content "Quantities have changed."
        expect(page).to have_field("Note", with: "A note")
        expect(page).to have_field("Reference ID", with: "Ref123")
        expect(page).to have_field("Quantity", with: "45")
      end
    end

    describe "trying to purchase after updating just the note/ref id fields" do
      before do
        click_link product.name
        click_link "Add to cart"
        choose account.to_s
        click_button "Continue"
        fill_in "Note", with: "A note"
        fill_in "Reference ID", with: "Ref123"
        click_button "Purchase"
      end

      it "purchases" do
        expect(page).to have_content("Order Receipt")
        expect(page).to have_content("Note: A note")
      end
    end

    it "can backdate an order", :js do # js needed for More options expansion
      two_days_ago = I18n.l(2.days.ago.to_date, format: :usa)
      three_days_ago = I18n.l(3.days.ago.to_date, format: :usa)
      visit facility_path(facility)
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"

      fill_in "Order date", with: two_days_ago
      select "Complete", from: "Order Status"

      fill_in "Fulfilled at", with: three_days_ago

      click_button "Purchase"

      expect(page).to have_content "Order Receipt"
      expect(page).to have_content(/Ordered For\n#{user.full_name}/i)
      expect(page).to have_css(".currency .estimated_cost", count: 0)
      expect(page).to have_css(".currency .actual_cost", count: 2) # Cost and Total

      expect(page).to have_content("Ordered Date\n#{two_days_ago}")

      click_link "Exit"
      click_link "Billing"
      expect(page).to have_content(three_days_ago)
    end

    it "can set a reference ID" do
      visit facility_path(facility)
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"

      fill_in "Reference ID", with: "Ref123"
      click_button "Purchase"
      expect(OrderDetail.last.reference_id).to eq("Ref123")
    end
  end

  describe "a service order" do
    let(:facility) { create(:setup_facility) }
    let(:service) { create(:setup_service, facility:) }
    let(:admin) { create(:user, :administrator) }
    let(:user) { create(:user) }
    let(:order) do
      create(:order, user:, created_by_user: user, facility:, account:)
    end
    let(:price_group) { service.price_groups.first }
    let(:account) do
      create(:account, :with_account_owner).tap do |account|
        AccountUser.create!(
          account:, user:, created_by_user: admin,
          user_role: AccountUser::ACCOUNT_PURCHASER,
        )
      end
    end

    before do
      create(
        :service_price_policy,
        product: service,
        price_group:,
      )
      create(
        :order_detail, account:,
                       order:, product: service,
      ).assign_estimated_price!

      login_as admin
      visit facility_user_switch_to_path(Facility.cross_facility, user)
      visit order_path(order)
    end

    it "can purchase the service" do
      expect(page).to have_content(service.name)
      expect(page).to have_button("Purchase")
    end

    context "when the service has an order form" do
      let(:service) { create(:setup_service, :with_survey, facility:) }

      it "requires the form to be submitted" do
        expect(page).to have_content("Please complete the online order form")
        expect(page).not_to have_button("Purchase")
      end

      context "when the service has the admin_skip_order_form flag on" do
        let(:service) do
          create(
            :setup_service,
            :with_survey,
            facility:,
            admin_skip_order_form: true,
          )
        end

        it "can purchase the service without filling the form" do
          expect(page).to have_content("Complete Online Order Form")
          expect(page).to have_button("Purchase")
        end
      end
    end
  end
end
