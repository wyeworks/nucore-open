require "rails_helper"

RSpec.describe "Schedule Rules", type: :system, js: true do
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
end
