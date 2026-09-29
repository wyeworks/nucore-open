# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::RelayReport do
  subject(:report) { described_class.new }

  let(:facility) { create(:setup_facility) }
  let!(:active_instrument) do
    create(:setup_instrument, facility:, name: "A Microscope", relay: build(:relay_syna, ip_port: 8080, secondary_outlet: 2, auto_logout: true, auto_logout_minutes: 15))
  end
  let!(:archived_instrument) do
    create(:setup_instrument, facility:, name: "B Sequencer", is_archived: true, relay: build(:relay_synb, auto_logout: false))
  end
  let!(:timer_instrument) { create(:setup_instrument, :timer, facility:) }

  it "has a header and one line per relay, excluding timers" do
    expect(report.to_csv.split("\n").length).to eq(3)
  end

  it "populates the report" do
    expect(report).to have_column_values(
      "Facility" => [facility.to_s, facility.to_s],
      "Instrument" => ["A Microscope", "B Sequencer"],
      "Active/Inactive" => ["Active", "Inactive"],
      "Relay Type" => ["Synaccess Revision A", "Synaccess Revision B"],
      "Relay IP Address" => ["192.168.1.1", "192.168.1.1"],
      "Relay IP Port" => ["8080", ""],
      "Outlet" => [active_instrument.relay.outlet.to_s, archived_instrument.relay.outlet.to_s],
      "Secondary Outlet" => ["2", ""],
      "Auto-Relay Shutoff After X Minutes" => ["15", "None"],
    )
  end

  it "has the email attributes" do
    expect(report).to have_attributes(
      filename: "instrument_relay_data.csv",
      description: "#{I18n.t('app_name')} Relay Data Export",
      text_content: "Your export is ready. Please see the attached file.",
    )
  end
end
