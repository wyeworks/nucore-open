# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service", :aggregate_failures do
  include RSpec::Matchers.clone # Give RSpec's `all` precedence over Capybara's

  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let!(:service) { create(:setup_service, facility:) }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:price_policy) { create(:service_price_policy, price_group: PriceGroup.base, product: service) }
  let(:user) { create(:user) }
  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service:, active: true, passer: service) }
  let!(:account_price_group_member) do
    create(:account_price_group_member, account:, price_group: price_policy.price_group)
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
        expect(page).to have_link("Complete Online Order Form")
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

          # back on the cart
          expect(page.find(cart_quantity_selector).value).to eq("4")

          expect(SangerSequencing::Sample.count).to eq(4)
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

          expect { visit edit_sanger_sequencing_submission_path(SangerSequencing::Submission.last) }.to raise_error(ActiveRecord::RecordNotFound)
        end

        it "renders the sample ID on the receipt" do
          expect(page).to have_content "Receipt"
          expect(page).to have_content "TEST123"
        end
      end
    end

    describe "submissions and primers" do
      let(:quantity) { 1 }
      let(:submission) { SangerSequencing::Submission.last }

      context "when submissions don't need a primer" do
        before do
          service.create_sanger_product(needs_primer: false)
        end

        it "does not show primer_name input" do
          click_link "Complete Online Order Form"

          expect(page).to have_field(
            "sanger_sequencing_submission[samples_attributes][0][customer_sample_id]"
          )
          expect(page).to_not have_field(
            "sanger_sequencing_submission[samples_attributes][0][primer_name]"
          )

          click_button("Save Submission")
          click_button("Purchase")

          expect(page).to have_content("Order Receipt")
          expect(page).to_not have_content("Primer")
        end
      end

      context "when submissions need a primer", :js do
        before do
          service.create_sanger_product(needs_primer: true)
        end

        it "allow to submit primer name" do
          click_link "Complete Online Order Form"

          expect(page).to have_field(
            "sanger_sequencing_submission[samples_attributes][0][primer_name]"
          )

          fill_in("sanger_sequencing_submission[samples_attributes][0][primer_name]", with: "Water")

          click_link("Add")

          # The primer name is copied when adding a new sample row
          expect(page).to have_field(
            "sanger_sequencing_submission[samples_attributes][1][primer_name]",
            with: "Water"
          )

          click_link("Add")

          fill_in("sanger_sequencing_submission[samples_attributes][1][primer_name]", with: "Juice")

          # Click copy primer to rows below button
          page.find(".nested_sanger_sequencing_submission_samples:nth-child(2) button").click

          # Copy the primer name to samples below second sample
          expect(page).to have_field(
            "sanger_sequencing_submission[samples_attributes][2][primer_name]",
            with: "Juice"
          )

          # First row, above second sample remains untouched
          expect(page).to have_field(
            "sanger_sequencing_submission[samples_attributes][0][primer_name]",
            with: "Water"
          )

          click_link("Add")

          # Allow empty primer name
          fill_in("sanger_sequencing_submission[samples_attributes][3][primer_name]", with: "")

          click_button("Save Submission")

          # back on the cart
          expect(page.find(cart_quantity_selector).value).to eq("4")

          expect(SangerSequencing::Sample.count).to eq(4)
          expect(submission.samples.count).to be 4
          expect(submission.samples[0].primer_name).to eq("Water")
          expect(submission.samples[1].primer_name).to eq("Juice")
          expect(submission.samples[2].primer_name).to eq("Juice")
          expect(submission.samples[3].primer_name).to eq("")

          click_button("Purchase")

          expect(page).to have_content("Order Receipt")
          expect(page).to have_content("Primer")
        end

        context "service primers" do
          let(:primers) do
            facility.sanger_sequencing_primers.insert_all([{ name: "Watermelon" }, { name: "Tomato" }])
            facility.sanger_sequencing_primers.all
          end

          before { service.sanger_product.update(primers:) }

          it "shows core primer options" do
            click_link "Complete Online Order Form"

            expect(page).to_not have_css(".ui-autocomplete")
            expect(page).to_not have_content("Watermelon")
            expect(page).to_not have_content("Tomato")

            page.find_field("sanger_sequencing_submission[samples_attributes][0][primer_name]").click

            expect(page).to have_css(".ui-autocomplete")
            expect(page).to have_content("Watermelon")
            expect(page).to have_content("Tomato")
          end
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
    let(:admin) { create(:user, :administrator) }
    before do
      login_as admin
      visit facility_user_switch_to_path(facility, user)
    end

    it_behaves_like "purchasing a sanger product and filling out the form"
  end

  describe "when the facility does not have sanger enabled" do
    before do
      login_as user
      facility.update(sanger_sequencing_enabled: false)
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
    end

    it_behaves_like "raises specified error", -> { click_link "Complete Online Order Form" }, ActionController::RoutingError
  end
end
