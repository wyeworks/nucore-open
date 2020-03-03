# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service", :aggregate_failures do
  include RSpec::Matchers.clone # Give RSpec's `all` precedence over Capybara's

  let(:facility) { FactoryBot.create(:setup_facility, sanger_sequencing_enabled: true) }
  let!(:service) { FactoryBot.create(:setup_service, facility: facility) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { FactoryBot.create(:service_price_policy, price_group: PriceGroup.base, product: service) }
  let(:user) { FactoryBot.create(:user) }
  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }
  let!(:account_price_group_member) do
    FactoryBot.create(:account_price_group_member, account: account, price_group: price_policy.price_group)
  end

  shared_examples_for "purchasing a sanger product and filling out the form" do
    let(:quantity) { 5 }
    let(:customer_id_selector) { ".nested_sanger_sequencing_submission_samples input[type=text]" }
    let(:cart_quantity_selector) { ".edit_order input[name^=quantity]" }
    before do
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      find(cart_quantity_selector).set(quantity.to_s)
    end

    it "sends the quantity without needing Update", :js do
      click_link "Complete Online Order Form"

      expect(page).to have_css(customer_id_selector, count: 5)
    end

    describe "without needing JS" do
      before do
        click_button "Update"
        click_link "Complete Online Order Form"
      end

      it "sets up the right number of text boxes" do
        expect(page).to have_css(customer_id_selector, count: 5)
      end

      it "has prefilled values in the text boxes with unique four digit numbers" do
        values = page.all(customer_id_selector).map(&:value)
        expect(values).to all(match(/\A\d{4}\z/))
        expect(values.uniq).to eq(values)
      end

      it "saves the form" do
        page.first(customer_id_selector).set("TEST123")
        click_button "Save Submission"

        expect(SangerSequencing::Sample.pluck(:customer_sample_id)).to include("TEST123")
        expect(SangerSequencing::Sample.count).to eq(5)
      end

      describe "adding/removing more fields", :js do
        it "adds fields" do
          page.click_link "Add"
          expect(page).to have_css("#{customer_id_selector}:enabled", count: 6)
          expect(page.all(customer_id_selector).last.value).to match(/\A\d{4}\z/)
          click_button "Save Submission"

          expect(SangerSequencing::Sample.count).to eq(6)

          # back on the cart
          expect(page.find(cart_quantity_selector).value).to eq("6")
        end

        it "can remove fields" do
          page.all(:link, "Remove").first.click
          expect(page).to have_css(customer_id_selector, count: 4)
          click_button "Save Submission"

          expect(SangerSequencing::Sample.count).to eq(4)

          # back on the cart
          expect(page.find(cart_quantity_selector).value).to eq("4")
        end
      end

      describe "blank fields" do
        it "does not allow submitting a blank value" do
          page.first(customer_id_selector).set("")
          click_button "Save Submission"

          expect(page.first(customer_id_selector).value).to be_blank
          expect(SangerSequencing::Sample.pluck(:customer_sample_id)).not_to include("")
        end
      end

      describe "saving and returning to the form" do
        before do
          page.first(customer_id_selector).set("TEST123")
          click_button "Save Submission"
          click_link "Edit Online Order Form"
        end

        it "returns to the form" do
          expect(page.first(customer_id_selector).value).to eq("TEST123")
        end
      end

      describe "after purchasing" do
        before do
          page.first(customer_id_selector).set("TEST123")
          click_button "Save Submission"
          click_button "Purchase"
          expect(Order.first).to be_purchased
        end

        it "can show, but not edit" do
          visit sanger_sequencing_submission_path(SangerSequencing::Submission.last)
          expect(page.status_code).to eq(200)

          visit edit_sanger_sequencing_submission_path(SangerSequencing::Submission.last)
          expect(page.status_code).to eq(404)
        end

        it "renders the sample ID on the receipt" do
          expect(page).to have_content "Receipt"
          expect(page).to have_content "TEST123"
        end
      end
    end
  end

  describe "as a normal user" do
    before do
      login_as user
    end

    it_behaves_like "purchasing a sanger product and filling out the form"
  end

  describe "while acting as another user" do
    let(:admin) { FactoryBot.create(:user, :administrator) }
    before do
      login_as admin
      visit facility_user_switch_to_path(facility, user)
    end

    it_behaves_like "purchasing a sanger product and filling out the form"
  end

  describe "when the facility does not have sanger enabled" do
    before do
      login_as user
      facility.update_attributes(sanger_sequencing_enabled: false)
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it "is not found" do
      click_link "Complete Online Order Form"
      expect(page.status_code).to eq(404)
    end
  end
end
