# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::ApiSpeedType do

  describe "loading from api" do
    before do
      stub_request(:get, %r{.+/SpeedType/\d+})
        .with(headers: { 'Accept' => 'application/json', 'User-Agent' => 'Ruby' })
        .to_return(status: 200, body: body, headers: {})
    end

    describe "active" do
      let(:body) { File.read(File.expand_path("../../fixtures/speed_type_api/active.json", __dir__)) }
      let(:api_speed_type) { described_class.find_or_initialize_from_api("109788") }

      it { is_expected.to be_a(UmassCorum::ApiSpeedType) }

      it "has the expected attributes" do
        expect(api_speed_type).to have_attributes(
          speed_type: "109788",
          version: 0,
          active: true,
          clazz: " ",
          date_added: an_instance_of(ActiveSupport::TimeWithZone),
          date_removed: be_blank,
          dept_desc: "Vet/Animal Science",
          dept_id: "A010400000",
          fund_code: "11000",
          fund_desc: "State Maintenance",
          manager_hr_emplid: "10038224",
          program_code: "A01",
          project_desc: " ",
          project_id: " ",
          error_desc: be_blank,
        )
      end
    end

    describe "expired" do
      let(:body) { File.read(File.expand_path("../../fixtures/speed_type_api/expired.json", __dir__)) }
      let(:api_speed_type) { described_class.find_or_initialize_from_api("150862") }
      it "has the expected attributes" do
        expect(api_speed_type).to have_attributes(
          speed_type: "150862",
          version: 0,
          active: false,
          clazz: " ",
          date_added: an_instance_of(ActiveSupport::TimeWithZone),
          date_removed: an_instance_of(ActiveSupport::TimeWithZone),
          dept_desc: "Vet/Animal Science",
          dept_id: "A010400000",
          fund_code: "11000",
          fund_desc: "State Maintenance",
          manager_hr_emplid: "10038224",
          program_code: "B03",
          project_desc: "National Multiple Sclerosis So",
          project_id: "S17110000000118",
          error_desc: "Speed_type has expired",
        )
      end
    end

    describe "not found" do
      let(:body) { File.read(File.expand_path("../../fixtures/speed_type_api/not_found.json", __dir__)) }
      let(:api_speed_type) { described_class.find_or_initialize_from_api("999999") }
      it "is something" do
        expect(api_speed_type).to have_attributes(
          speed_type: "999999",
          error_desc: "Speed_Type does not exist"
        )
      end
    end
  end
end
