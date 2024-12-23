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
      FactoryBot.create(:setup_instrument, pricing_mode: "Duration", facility:)
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
      FactoryBot.create(:setup_instrument, pricing_mode: "Schedule Rule", facility:)
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

  describe "daily booking instrument" do
    let(:instrument) { create :setup_instrument, :daily_booking }
    let(:facility) { instrument.facility }

    before do
      login_as user
    end

    context do
      it "does not show discounts in index table" do
        expect(instrument.schedule_rules).to_not be_empty

        visit facility_instrument_schedule_rules_path(facility, instrument)

        expect(page).to_not have_content("Discount")
        within("table") do
          expect(page).to have_content("Days of Week")
        end
      end

      it "works as expected on create" do
        # Destroy other rules so we don't deal with conflicts
        instrument.schedule_rules.destroy_all

        visit new_facility_instrument_schedule_rule_path(facility, instrument)

        expect(page).to_not have_content("Discount")

        check("Tue")
        click_button("Create")

        expect(page).to have_content(I18n.t("controllers.schedule_rules.create"))
      end

      it "works as expected on edit" do
        schedule_rule = instrument.schedule_rules.last
        # Destroy other rules so we don't deal with conflicts
        instrument.schedule_rules.where.not(id: schedule_rule.id).destroy_all

        visit edit_facility_instrument_schedule_rule_path(facility, instrument, schedule_rule)

        expect(page).to_not have_content("Discount")

        check("Mon")
        check("Tue")
        check("Wed")

        expect(page).to have_field("schedule_rule[start_hour]")
        expect(page).to have_field("schedule_rule[start_min]")
        expect(page).to have_field("schedule_rule[end_hour]")
        expect(page).to have_field("schedule_rule[end_min]")

        click_button("Update")

        expect(page).to have_content(I18n.t("controllers.schedule_rules.update"))
      end
    end

    context "when instrument has start_time_disabled on" do
      before do
        instrument.update(start_time_disabled: true)
      end

      it "allows to select days but not time" do
        schedule_rule = instrument.schedule_rules.last
        # Destroy other rules so we don't deal with conflicts
        instrument.schedule_rules.where.not(id: schedule_rule.id).destroy_all

        visit edit_facility_instrument_schedule_rule_path(facility, instrument, schedule_rule)

        expect(page).to_not have_content("Discount")

        check("Mon")
        check("Tue")
        check("Wed")

        expect(page).to_not have_field("schedule_rule[start_hour]")
        expect(page).to_not have_field("schedule_rule[start_min]")
        expect(page).to_not have_field("schedule_rule[end_hour]")
        expect(page).to_not have_field("schedule_rule[end_min]")

        click_button("Update")

        expect(page).to have_content(I18n.t("controllers.schedule_rules.update"))
        expect(page).to_not have_css("#calendar")
      end
    end
  end
end
