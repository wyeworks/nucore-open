# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Placing an item order" do
  let!(:product) { FactoryBot.create(:setup_item) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { product.facility }
  let!(:price_policy) do
    FactoryBot.create(:item_price_policy,
                      price_group: PriceGroup.base, product: product,
                      unit_cost: 33.25)
  end
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end
  let(:user) { FactoryBot.create(:user) }

  before do
    login_as user
  end

  describe "adding an item to the cart" do
    def add_to_cart
      visit "/"
      click_link facility.name
      click_link product.name
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it "can place an order", :aggregate_failures do
      add_to_cart
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
      expect(page).to have_content "Ordered By\n#{user.full_name}"
      expect(page).to have_content "$33.25"
    end

    it "can place an order with a note if the feature is enabled for the product" do
      product.update_attributes!(user_notes_field_mode: "optional")
      add_to_cart
      fill_in "Note", with: "This is a note"
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
      expect(page).to have_content "This is a note"
    end

    it "cannot place an order while missing the note if it is required, and has a custom label" do
      product.update!(
        user_notes_field_mode: "required",
        user_notes_label: "Show me what you got",
      )
      add_to_cart
      click_button "Purchase"
      expect(page).to have_content("may not be blank")

      fill_in "Show me what you got", with: "A note"
      click_button "Purchase"
      expect(page).to have_content "Order Receipt"
    end
  end

  describe "adding a bundle" do
    let(:bundle) { FactoryBot.create(:bundle, facility: facility) }

    def add_to_cart
      visit facility_bundle_path(facility.url_name, bundle.url_name)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    describe "that has multiple items" do
      let!(:product2) { FactoryBot.create(:setup_item, facility: facility) }

      before do
        FactoryBot.create(:item_price_policy, price_group: PriceGroup.base, product: product2)
        bundle.bundle_products.create!(product: product, quantity: 2)
        bundle.bundle_products.create!(product: product2, quantity: 3)
      end

      it "adds both items to the cart and can purchase them" do
        add_to_cart
        expect(page).to have_content(product.name)
        expect(page).to have_content(product2.name)
        expect(page).to have_link("Remove").once # Only has one "remove" link

        click_button "Purchase"
        expect(page).to have_content "Order Receipt"
      end
    end

    describe "that has a service with an order form" do
      let(:service) { FactoryBot.create(:setup_service, :with_order_form) }
      before do
        FactoryBot.create(:service_price_policy, price_group: PriceGroup.base, product: service)
        bundle.bundle_products.create!(product: service, quantity: 2)
      end

      it "adds the item as a single line item" do
        add_to_cart
        expect(page).to have_content(service.name).once
      end
    end

    describe "that has a timed service" do
      let(:timed_service) { FactoryBot.create(:setup_timed_service) }
      before do
        FactoryBot.create(:timed_service_price_policy, price_group: PriceGroup.base, product: timed_service)
        bundle.bundle_products.create!(product: timed_service, quantity: 90)
      end

      it "adds the item as a single line item" do
        add_to_cart
        expect(page).to have_content(timed_service.name).once
        expect(page).to have_content("1:30")
      end
    end

    describe "that has a multiple of instruments" do
      let!(:instrument) { FactoryBot.create(:setup_instrument, facility: facility) }
      let!(:price_policy) do
        FactoryBot.create(:instrument_price_policy,
                          price_group: PriceGroup.base, product: instrument)
      end

      before do
        bundle.bundle_products.create!(product: instrument, quantity: 2)
      end

      it "adds two rows to the cart" do
        add_to_cart
        expect(page).to have_content(instrument.name).twice
        expect(page).to have_link("Remove").once # Only has one "remove" link
        expect(page).not_to have_button("Purchase")
        expect(page).to have_link("Make a Reservation").twice
      end
    end
  end
end
