# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Schedule Rules" do
  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:setup_instrument, facility:, skip_schedule_rules: true) }
  let(:admin) { create(:user, :administrator) }

  before do
    login_as admin
  end

  it "displays the schedule times correctly" do
    schedule_rule = create(:schedule_rule, product: instrument, start_hour: 9, end_hour: 17)

    expect(instrument.schedule_rules.count).to eq(1)
    expect(schedule_rule.persisted?).to be true

    visit facility_instrument_schedule_rules_path(facility, instrument)

    expect(page).to have_content("9:00 AM")
    expect(page).to have_content("5:00 PM")

    expect(page.text).not_to include("undefined")
  end

  describe "product pricing permission" do
    let(:user) { create(:user) }
    let!(:facility_user_permission) do
      FacilityUserPermission.create(
        user:, facility:, product_management: true, read_access: true,
      )
    end
    let(:schedule_rule) { create(:schedule_rule, product: instrument) }

    before { login_as user }

    context "when product pricing disabled" do
      it "does not show price group discounts section" do
        visit edit_facility_instrument_schedule_rule_path(facility, instrument, schedule_rule)

        expect(page).not_to have_content("Price Group Discounts")
      end
    end

    context "when product pricing enabled" do
      before do
        facility_user_permission.update(product_pricing: true)
      end

      it "shows price group discounts section" do
        visit edit_facility_instrument_schedule_rule_path(facility, instrument, schedule_rule)

        expect(page).to have_content("Price Group Discounts")
      end
    end
  end
end
