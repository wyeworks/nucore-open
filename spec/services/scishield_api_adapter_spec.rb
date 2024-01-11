# frozen_string_literal: true

require "rails_helper"

RSpec.describe ResearchSafetyAdapters::ScishieldApiAdapter do
  subject(:adapter) { described_class.new(user) }
  let(:user) { create(:user, email: "research@osu.edu") }
  let(:api_endpoint) { adapter.client.api_endpoint(user.email) }

  context "Scishield trainings do not exist in database" do
    describe "with a successful response" do
      let(:response) { File.expand_path("../fixtures/scishield/success.json", __dir__) }

      before do
        stub_request(:get, api_endpoint)
          .to_return(
            body: File.new(response),
            status: 200,
          )
      end

      it "is certified for Lab Safety" do
        certificate = instance_double(ResearchSafetyCertificate, name: "Lab Safety Training for Lab Workers")
        expect(adapter).to be_certified(certificate)
      end

      it "is certified for Hazardous Waste" do
        certificate = instance_double(ResearchSafetyCertificate, name: "Hazardous Waste Awareness Training")
        expect(adapter).to be_certified(certificate)
      end

      it "is not certified for Fire Extinguisher Course" do
        certificate = instance_double(ResearchSafetyCertificate, name: "OSU Fire Extinguisher Course (online) ")
        expect(adapter).not_to be_certified(certificate)
      end

      it "only calls the response once" do
        expect(adapter.client).to receive(:certifications_for).once.and_call_original
        adapter.certified? instance_double(ResearchSafetyCertificate, name: "Lab Safety Training for Lab Workers")
        adapter.certified? instance_double(ResearchSafetyCertificate, name: "Hazardous Waste Awareness Training")
        adapter.certified? instance_double(ResearchSafetyCertificate, name: "RANDOM")
      end

      context "without a data attribute" do
        let(:response) { File.expand_path("../fixtures/scishield/empty_success.json", __dir__) }

        before do
          stub_request(:get, api_endpoint)
            .to_return(
              body: File.new(response),
              status: 200,
            )
        end

        it "gives an empty array" do
          expect(adapter.certified_course_names_from_api).to eq []
        end
      end
    end

    describe "unable to connect" do
      before do
        stub_request(:get, api_endpoint)
          .to_timeout
      end

      it "raises an error" do
        expect { adapter.certified?(anything) }.to raise_error(Timeout::Error)
      end
    end

    describe "the user is not found" do
      let(:response) { File.expand_path("../fixtures/scishield/user_not_found.json", __dir__) }
      before do
        stub_request(:get, api_endpoint)
          .to_return(
            body: File.new(response),
            status: 200,
          )
      end

      it "doesn't raise an error, and doesn't certify anything" do
        random = instance_double(ResearchSafetyCertificate, name: "RANDOM")
        expect(adapter).not_to be_certified(random)
      end
    end

    describe "the user is found but the response includes an error" do
      let(:response) { File.expand_path("../fixtures/scishield/errors.json", __dir__) }
      before do
        stub_request(:get, api_endpoint)
          .to_return(
            body: File.new(response),
            status: 403,
          )
      end

      it "raises an error" do
        expect { adapter.certified?(anything) }.to raise_error(/Forbidden: This route can only be accessed by authenticated users/)
      end
    end
  end

  context "Scishield training exists in database" do
    let!(:course_names) { Array.new(3) { create(:scishield_training, user_id: user.id).course_name } }

    it "gets course names from database" do
      expect(adapter.certified_course_names).to contain_exactly(*course_names)
    end
  end
end
