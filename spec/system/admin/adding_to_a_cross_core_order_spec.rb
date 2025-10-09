# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Adding to an existing order for cross core", :js do
  let(:facility) { product.facility }
  let(:order) { create(:purchased_order, product: product, ordered_at: 1.week.ago) }
  let(:user) { create(:user, :staff, facility: facility) }
  let!(:other_account) { create(:nufs_account, :with_account_owner, owner: order.user, description: "Other Account") }
  let(:facility2) { create(:setup_facility) }
  let!(:facility2_credit_card_account) { create(:account, :with_account_owner, type: "CreditCardAccount", owner: order.user, description: "Credit Card Account", facility: facility2) }
  let!(:facility2_account) { create(:nufs_account, :with_account_owner, owner: order.user, description: "Internal Account", facility: facility2) }
  let(:price_group) { PriceGroup.base }
  let(:external_price_group) { PriceGroup.external }

  before do
    create(:account_price_group_member, account: facility2_account, price_group: external_price_group)
    create(:account_price_group_member, account: facility2_account, price_group:)

    login_as user
  end

  describe "adding a backdated service with an order form" do
    let(:product) { create(:setup_service, :with_facility_account, :with_order_form) }
    let!(:cross_core_product_facility2) { create(:setup_service, :with_facility_account, :with_order_form, facility: facility2, cross_core_ordering_available: true) }
    let(:fulfilled_at_string) { I18n.l(1.day.ago.to_date, format: :usa) }

    before do
      visit facility_order_path(facility, order)

      select_from_chosen facility2.name, from: "add_to_order_form[facility_id]", scroll_to: :center
      select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]", scroll_to: :center
      select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center
      fill_in "add_to_order_form[quantity]", with: "1"
      select_from_chosen "Complete", from: "Order Status"
      fill_in "add_to_order_form[fulfilled_at]", with: fulfilled_at_string
      click_button "Add to Cross-Core Order"
    end

    it "does not have an ordered_at yet" do
      expect(page).to have_content("Your order includes one or more incomplete item")

      expect(order.reload.order_details.count).to be(1)
      expect(OrderDetail.order(:id).last.ordered_at).to be_blank
    end

    # This expectation is in its own it because it kept failing, so we'd like to get more information about the failure.
    it "requires a file to be uploaded before adding to the order" do
      expect(page).to have_content("Your order includes one or more incomplete items.")
    end

    describe "after uploading the file" do
      before do
        within("#merge-order-missing-order-info-reminder") do
          click_link "Upload Order Form"
        end
        attach_file "stored_file[file]", Rails.root.join("spec", "files", "template1.txt")
        click_button "Upload"
      end

      it "sets the expected attributes", :aggregate_failures do
        expect(page).to have_content("Order File uploaded successfully.")

        project = order.reload.cross_core_project

        expect(project).to be_present
        expect(project.orders.count).to be(2)

        order_detail = project.orders.last.order_details.first
        expect(order_detail).to be_complete
        expect(I18n.l(order_detail.fulfilled_at.to_date, format: :usa)).to eq(fulfilled_at_string)
        expect(I18n.l(order_detail.ordered_at.to_date, format: :usa)).to eq(fulfilled_at_string)
      end
    end
  end

  context "when it does not require an order form" do
    let(:product) { create(:setup_service, :with_facility_account) }
    let!(:cross_core_product_facility2) { create(:setup_service, :with_facility_account, facility: facility2, cross_core_ordering_available: true) }
    let!(:service_price_policy) { create(:service_price_policy, product: cross_core_product_facility2, price_group: external_price_group ) }

    before do
      visit facility_order_path(facility, order)

      select_from_chosen facility2.name, from: "add_to_order_form[facility_id]", scroll_to: :center
      select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]"
      select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center
      fill_in "add_to_order_form[quantity]", with: "1"
      click_button "Add to Cross-Core Order"
    end

    it "uploads file" do
      find("h3", text: facility2.to_s).click
      find_all("a", text: "0 Uploaded").last.click
      expect(page).to have_content("Upload Results")
      attach_file "qqfile", Rails.root.join("spec", "files", "template1.txt"), make_visible: true
      expect(page).to have_content("Download all as zip...")
      click_button "Done"
      expect(page).to have_content("1 Uploaded")
    end
  end

  describe "adding an instrument reservation" do
    describe "from another facility", :js do
      let(:product) { create(:setup_item, :with_facility_account) }
      let!(:instrument) { create(:setup_instrument, facility: facility2, cross_core_ordering_available: true) }
      let(:user) { create(:user, :facility_administrator, facility:) }
      let!(:current_price_policy) do
        create(:item_price_policy,
          product: instrument,
          price_group:,
          start_date: 1.day.ago,
        )
      end

      describe "with one reservation" do
        before do
          visit facility_order_path(facility, order)
          select_from_chosen facility2.name, from: "add_to_order_form[facility_id]"
          select_from_chosen instrument.name, from: "add_to_order_form[product_id]"
          fill_in "add_to_order_form[quantity]", with: "1"
          select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center
          click_button "Add to Cross-Core Order"
        end

        it "requires a reservation to be set up before adding to the order" do
          expect(page).to have_content("Your order includes one or more incomplete items.")

          within("#merge-order-missing-order-info-reminder") do
            click_link "Make a Reservation"
          end
          select facility2_account.to_s, from: "Payment Source"
          click_button "Create"

          expect(page).to have_content("The reservation was successfully created")

          expect(order.reload.order_details.count).to be(1)
          project = order.cross_core_project
          expect(project).to be_present
          expect(project.orders.last.order_details.last.product).to eq(instrument)
          expect(project.orders.last.account_id).to eq(facility2_account.id)
          expect(project.orders.last.state).to eq("purchased")
        end

        it "brings you back to the facility order path on 'Cancel'" do
          within("#merge-order-missing-order-info-reminder") do
            click_link "Make a Reservation"
          end
          click_link "Cancel"

          expect(current_path).to eq(facility_order_path(facility, order))
          expect(page).to have_link("Make a Reservation")
        end
      end

      describe "with a product from before" do
        let(:facility2) { create(:setup_facility) }
        let!(:product2) { create(:setup_item, facility: facility2, cross_core_ordering_available: true) }

        before do
          create(:item_price_policy,
            product: product2,
            price_group:,
            start_date: 1.day.ago,
          )

          visit facility_order_path(facility, order)
          select_from_chosen facility2.name, from: "add_to_order_form[facility_id]"
          select_from_chosen product2.name, from: "add_to_order_form[product_id]", scroll_to: :center
          select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center
          fill_in "add_to_order_form[quantity]", with: "1"
          click_button "Add to Cross-Core Order"
        end

        it "sets the merge_with_order_id until the reservation is created" do
          expect(page).to have_content("was successfully added to this order")

          project = order.reload.cross_core_project
          second_facility_order = project.orders.last

          select_from_chosen facility2.name, from: "add_to_order_form[facility_id]", scroll_to: :center
          select_from_chosen instrument.name, from: "add_to_order_form[product_id]"
          select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center
          fill_in "add_to_order_form[quantity]", with: "1"
          click_button "Add to Cross-Core Order"

          expect(page).to have_content("Your order includes one or more incomplete items")

          # This is the second order for this facility so it has a merge_order set
          expect(project.reload.orders.last.merge_with_order_id).to eq(second_facility_order.id)

          within("#merge-order-missing-order-info-reminder") do
            click_link "Make a Reservation"
          end

          select facility2_account.to_s, from: "Payment Source"
          click_button "Create"

          # After the reservation is created, the order_detail is moved to the merge_order
          # and the temporary merge order should be destroyed (or have no merge_with_order_id)
          expect(page).to have_content("The reservation was successfully created")

          project.reload
          expect(project.orders.where.not(merge_with_order_id: nil)).to be_empty
        end
      end
    end
  end

  describe "adding an item from another facility" do
    let(:product) { create(:setup_item, :with_facility_account, cross_core_ordering_available: false) }
    let!(:product2) { create(:setup_item, :with_facility_account, facility: facility2, cross_core_ordering_available: false) }
    let!(:cross_core_product_facility) { create(:setup_item, :with_facility_account, facility:, cross_core_ordering_available: true) }
    let!(:cross_core_product_facility2) { create(:setup_item, :with_facility_account, facility: facility2, cross_core_ordering_available: true) }
    let!(:current_price_policy) do
      create(:item_price_policy,
        product: cross_core_product_facility2,
        price_group:,
        start_date: 1.day.ago,
      )
    end

    before do
      visit facility_order_path(facility, order)
    end

    context "with staff role" do
      it "changes the button text" do
        expect(page).to have_button("Add To Order")
        select_from_chosen facility2.name, from: "add_to_order_form[facility_id]"
        select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]"
        expect(page).to have_button("Add to Cross-Core Order")
      end

      it "account for another facility cannot be selected" do
        expect(page).not_to have_selector("option", text: facility2_credit_card_account.to_s, visible: false)
      end

      it "creates a new order for the selected facility" do
        expect(page).not_to have_content("Cross Core Project ID")
        expect(page).to have_selector("option", text: cross_core_product_facility.name, visible: false)
        expect(page).to have_selector("option", text: product.name, visible: false)

        select_from_chosen facility2.name, from: "add_to_order_form[facility_id]", scroll_to: :center
        select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]"
        expect(page.has_selector?("option", text: facility2_credit_card_account.to_s, visible: false)).to be(true)
        select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center

        expect(page).not_to have_selector("option", text: product2.name, visible: false)

        click_button "Add to Cross-Core Order"

        expect(page).to have_content("#{cross_core_product_facility2.name} was successfully added to this order.")
        expect(page).to have_content(facility2.to_s), count: 2
        expect(page).to have_content(user.full_name), count: 2

        order.reload

        project = order.cross_core_project
        expect(project).to be_present

        expect(page).to have_content("Cross-Core Project ID")
        expect(page).to have_content(project.name)

        expect(project.orders.first.state).to eq("purchased")
        expect(project.orders.last.state).to eq("purchased")

        project_total = project.orders.sum(&:total)
        expect(page).to have_content("Cross-Core Project Total")
        expect(page).to have_content(project_total)
      end
    end

    context "with admin role" do
      let(:user) { create(:user, :facility_administrator, facility:) }

      it "changes the button text" do
        expect(page).to have_button("Add To Order")
        select_from_chosen facility2.name, from: "add_to_order_form[facility_id]"
        select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]"
        expect(page).to have_button("Add to Cross-Core Order")
      end

      it "creates a new order for the selected facility" do
        expect(page).not_to have_content("Cross Core Project ID")
        expect(page).to have_selector("option", text: cross_core_product_facility.name, visible: false)
        expect(page).to have_selector("option", text: product.name, visible: false)
        expect(page).not_to have_selector("option", text: facility2_credit_card_account.to_s, visible: false)

        select_from_chosen facility2.name, from: "add_to_order_form[facility_id]", scroll_to: :center
        select_from_chosen cross_core_product_facility2.name, from: "add_to_order_form[product_id]"
        select_from_chosen facility2_account.to_s, from: "Payment Source", scroll_to: :center

        expect(page).not_to have_selector("option", text: product2.name, visible: false)

        click_button "Add to Cross-Core Order"

        expect(page).to have_content("#{cross_core_product_facility2.name} was successfully added to this order.")
        expect(page).to have_content(facility2.to_s), count: 2
        expect(page).to have_content(user.full_name), count: 2

        order.reload

        project = order.cross_core_project
        expect(project).to be_present

        expect(page).to have_content("Cross-Core Project ID")
        expect(page).to have_content(project.name)

        project_total = project.orders.sum(&:total)
        expect(page).to have_content("Cross-Core Project Total")
        expect(page).to have_content(project_total)
      end
    end

  end

end
