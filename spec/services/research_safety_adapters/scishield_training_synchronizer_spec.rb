require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldTrainingSynchronizer do
  let!(:user) { create(:user, email: "Todd.Miller@oregonstate.edu") }
  let(:email) { user.email }
  let(:synchronizer) { described_class.new }
  let(:response) { File.expand_path("../../fixtures/scishield/success.json", __dir__) }
  let(:course_names) { ["Lab Safety Training for Lab Workers", "OSU Fire Extinguisher Course (in person)", "Hazardous Waste Awareness Training"] }
  let(:satus_code) { nil }
  let(:api_endpoint) { ResearchSafetyAdapters::ScishieldApiClient.new.api_endpoint(user.email) }

  before do
    stub_request(:get, api_endpoint)
      .to_return(
        status: status_code,
        body: File.new(response)
      )
  end

  context "when the API responds without error" do
    let(:status_code) { "200" }

    it "adds courses to database" do
      expect(ScishieldTraining.count).to eq 0
      synchronizer.synchronize
      expect(ScishieldTraining.count).to eq 3
      expect(ScishieldTraining.all.map(&:course_name)).to contain_exactly(*course_names)
    end
  end

  context "when the API responds with error" do
    before { 2.times { create(:scishield_training, user_id: 1) } }

    context "when the response is missing the data attribute" do
      let(:response) { File.expand_path("../../fixtures/scishield/empty_success.json", __dir__) }
      let(:status_code) { "200" }

      it "does not add courses to database" do
        expect(ScishieldTraining.count).to eq 2
        synchronizer.synchronize
        expect(ScishieldTraining.count).to eq 2
      end
    end

    context "when the API responds with a 500 error" do
      let(:status_code) { 500 }

      it "does not add courses to database" do
        expect(ScishieldTraining.count).to eq 2
        synchronizer.synchronize
        expect(ScishieldTraining.count).to eq 2
      end
    end

    context "when the API responds with a 403 error" do
      let(:status_code) { 403 }

      it "does not add courses to database" do
        expect(ScishieldTraining.count).to eq 2
        synchronizer.synchronize
        expect(ScishieldTraining.count).to eq 2
      end
    end

    context "when the API responds with a 404 error" do
      let(:status_code) { 404 }

      it "does not add courses to database" do
        expect(ScishieldTraining.count).to eq 2
        synchronizer.synchronize
        expect(ScishieldTraining.count).to eq 2
      end
    end
  end
end
