# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Instrument Scheduling Tab" do
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:user) { FactoryBot.create(:user, :administrator) }
  let!(:expert_access_group) { create(:product_access_group, name: "Expert", product: instrument) }

  before do
    login_as user
  end

  context "when the instrument has duration pricing mode" do
    let!(:instrument) do
      FactoryBot.create(:setup_instrument, pricing_mode: "Duration", facility: facility)
    end

    context "new schedule rule" do
      before do
        visit new_facility_instrument_schedule_rule_path(facility, instrument)
      end

      it "shows common Schedule rule fields, but NOT Price Group Discounts" do
        expect(page).to have_content(instrument.name)
        expect(page).to have_content("Restricted to only these groups")
        expect(page).to have_content("Add Schedule Rule")
        expect(page).not_to have_content("Price Group Discounts")

        check "Sun"

        select "7", from: "schedule_rule_start_hour"
        select "8", from: "schedule_rule_end_hour"

        click_button "Create"

        expect(page).to have_content("Days of Week")
        expect(page).to have_content("Start Time")
        expect(page).to have_content("End Time")
        expect(page).not_to have_content("Discount (%)")
      end
    end

    context "edit schedule rules" do
      before do
        visit edit_facility_instrument_schedule_rule_path(facility, instrument, instrument.schedule_rules.first)
      end

      it "shows common Schedule rule fields, but NOT Price Group Discounts" do
        expect(page).to have_content("Editing Schedule Rule")
        expect(page).not_to have_content("Price Group Discounts")
        expect(page).to have_content("Restricted to only these groups")

        check "Mon"

        click_button "Update"

        expect(page).to have_content("Days of Week")
        expect(page).to have_content("Start Time")
        expect(page).to have_content("End Time")
        expect(page).not_to have_content("Discount (%)")
      end
    end
  end

  context "when the instrument has schedule pricing mode" do
    let!(:instrument) do
      FactoryBot.create(:setup_instrument, pricing_mode: "Schedule Rule", facility: facility)
    end

    context "new schedule rule" do
      before do
        visit new_facility_instrument_schedule_rule_path(facility, instrument)
      end

      it "shows all Schedule rule fields" do
        expect(page).to have_content(instrument.name)
        expect(page).to have_content("Add Schedule Rule")
        expect(page).to have_content("Price Group Discounts")
        expect(page).to have_content("Restricted to only these groups")

        check "Sun"

        select "7", from: "schedule_rule_start_hour"
        select "8", from: "schedule_rule_end_hour"

        click_button "Create"

        expect(page).to have_content("Days of Week")
        expect(page).to have_content("Start Time")
        expect(page).to have_content("End Time")
        expect(page).to have_content("Discount (%)")
      end
    end

    context "edit schedule rules" do
      before do
        visit edit_facility_instrument_schedule_rule_path(facility, instrument, instrument.schedule_rules.first)
      end

      it "shows all Schedule rule fields" do
        expect(page).to have_content("Editing Schedule Rule")
        expect(page).to have_content("Price Group Discounts")
        expect(page).to have_content("Restricted to only these groups")
        # As the instrument has no highlighted price groups, header should not be displayed
        expect(page).not_to have_content("Highlighted Price Groups")
        expect(page).to have_content("Price Groups")
      end
    end
  end

end
