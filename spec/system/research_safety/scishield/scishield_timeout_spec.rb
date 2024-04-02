# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Scishield timeout", safety_adapter_class: ResearchSafetyAdapters::ScishieldApiAdapter do
  let!(:user) { create(:user) }
  let(:admin) { create(:user, :administrator) }
  let!(:instrument) { FactoryBot.create(:setup_instrument) }
  let(:facility) { instrument.facility }
  let!(:cert1) { create(:product_certification_requirement, product: instrument).research_safety_certificate }
  let!(:cert2) { create(:product_certification_requirement, product: instrument).research_safety_certificate }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:account_price_group_member) do
    create(
      :account_price_group_member,
      account:,
      price_group: instrument.price_policies.first.price_group,
    )
  end

  before do
    # This will cause ResearchSafetyAdapters::ScishieldApiClient#certifications_for
    # to raise ResearchSafetyAdapters::ScishieldApiError
    allow_any_instance_of(ResearchSafetyAdapters::ScishieldApiClient).to(
      receive(:training_api_request).and_raise(Net::OpenTimeout)
    )
  end

  describe "viewing a user's certificates" do
    before do
      login_as admin
      visit facility_user_user_research_safety_certifications_path Facility.cross_facility, user
    end

    it "displays an error on the page" do
      expect(page).to have_content I18n.t("services.research_safety_adapters.scishield_api_client.request_failed")
    end
  end

  describe "making a reservation" do
    before do
      login_as user
      visit facility_path(facility)
      click_link instrument.name
    end

    it "displays an error on the page" do
      click_button "Create"
      expect(page).to have_content I18n.t("services.research_safety_adapters.scishield_api_client.request_failed")
    end
  end
end
