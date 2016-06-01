require "rails_helper"

RSpec.describe "Purchasing a Sanger Sequencing service", :aggregate_failures do
  include RSpec::Matchers.clone # Give RSpec's `all` precedence over Capybara's

  let!(:service) { FactoryGirl.create(:setup_service) }
  let!(:account) { FactoryGirl.create(:nufs_account, :with_account_owner, owner: user) }
  let(:facility) { service.facility }
  let!(:price_policy) { FactoryGirl.create(:service_price_policy, price_group: PriceGroup.base.first, product: service) }
  let(:user) { FactoryGirl.create(:user) }
  let(:external_service) { create(:external_service, location: new_sanger_sequencing_submission_path) }
  let!(:sanger_order_form) { create(:external_service_passer, external_service: external_service, active: true, passer: service) }

  before do
    login_as user
  end

  describe "submission form" do
    let(:quantity) { 5 }
    let(:customer_id_selector) { ".edit_sanger_sequencing_submission input[type=text]" }
    before do
      visit facility_service_path(facility, service)
      click_link "Add to cart"
      choose account.to_s
      click_button "Continue"
      find(".edit_order input[type=text]").set(quantity.to_s)
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
  end
end
