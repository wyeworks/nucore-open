# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Editing an instrument" do
  describe "daily booking instrument" do
    let(:instrument) { create :setup_instrument, :daily_booking }
    let(:facility) { instrument.facility }
    let(:user) { create :user, :administrator }

    before do
      login_as user
    end

    it "can edit the instrument" do
      visit edit_facility_instrument_path(facility, instrument)

      expect(page).to have_content(instrument.name)

      fill_in("Minimum (days)", with: "2")

      click_button("Save")

      expect(page).to have_content("Instrument was successfully updated")
    end

    context "switching start_time_disabled on" do
      let(:schedule_rule) do
        instrument.schedule_rules.destroy_all
        create(
          :schedule_rule,
          product: instrument,
          start_hour: 9, start_min: 0, end_hour: 17, end_min: 0,
        )
      end

      def schedule_rule_times(schedule_rule)
        schedule_rule.reload.as_json(only: [:start_hour, :start_min, :end_hour, :end_min])
      end

      it "update schedule rules if start_time_disabled is switched on" do
        visit edit_facility_instrument_path(facility, instrument)

        check("Start Time Disabled")

        expect { click_button("Save") }.to change {
          schedule_rule_times(schedule_rule.reload)
        }.from(
          schedule_rule_times(schedule_rule)
        ).to(
          ScheduleRule.full_day_attributes.with_indifferent_access
        )

        expect(page).to have_content("Instrument was successfully updated")
      end
    end
  end
end
