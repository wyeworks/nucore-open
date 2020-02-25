require "rails_helper"

RSpec.describe "Training Requests", feature_setting: { training_requests: true, reload_routes: true } do
  let(:facility) { create(:setup_facility) }

  let(:user) { create(:user) }
  let!(:account) { FactoryBot.create(:nufs_account, :with_account_owner, owner: user) }

  before do
    login_as user
  end

  describe "with an unrestricted item" do
    let!(:item) { create(:setup_item, facility: facility) }
    before do
      create(:item_price_policy, product: item, price_group: PriceGroup.base)
    end

    it "can add the unrestricted item to the cart" do
      visit facility_path(facility.url_name)
      click_link item.name
      expect(page).to have_link "Add to cart"
    end
  end

  describe "with a restricted item" do
    let!(:item) { create(:setup_item, requires_approval: true, facility: facility) }

    it "can submit a training request" do
      visit facility_path(facility.url_name)
      click_link item.name
      expect(page).not_to have_link("Add to cart")
      expect(page).to have_content("Would you like to be contacted by the #{I18n.t('facility_downcase')} for access")
      click_button "Yes"
      expect(page).to have_content("has been submitted")
    end
  end

  describe "with a restricted item, but requests are disabled" do
    let!(:item) { create(:setup_item, requires_approval: true, allows_training_requests: false, facility: facility) }

    it "just has a link if requests are disabled" do
      visit facility_path(facility.url_name)
      click_link item.name
      expect(page).not_to have_link("Add to cart")
      expect(page).to have_content("Please contact the #{I18n.t('facility_downcase')} to request access")
    end
  end

  describe "with an unrestricted instrument" do
    let!(:instrument) { create(:setup_instrument, facility: facility) }
    before do
      create(:instrument_price_policy, product: instrument, price_group: PriceGroup.base)
    end

    it "can add the unrestricted instrument to the cart" do
      visit facility_path(facility.url_name)
      click_link instrument.name
      # i.e. we're on the new reservation page
      expect(page).to have_field("Reserve Start")
    end
  end

  describe "with a restricted instrument" do
    let!(:instrument) { create(:setup_instrument, requires_approval: true, facility: facility) }

    it "can submit a training request" do
      visit facility_path(facility.url_name)
      click_link instrument.name
      expect(page).not_to have_field("Reserve Start")
      expect(page).to have_content("Would you like to be contacted by the #{I18n.t('facility_downcase')} for access")
      click_button "Yes"
      expect(page).to have_content("has been submitted")
    end
  end

  describe "with a restricted instrument, but requests are disabled" do
    let!(:instrument) { create(:setup_instrument, requires_approval: true, allows_training_requests: false, facility: facility) }

    it "just has a link if requests are disabled" do
      visit facility_path(facility.url_name)
      click_link instrument.name
      expect(page).not_to have_field("Reserve Start")
      expect(page).to have_content("Please contact the #{I18n.t('facility_downcase')} to request access")
    end
  end
end
