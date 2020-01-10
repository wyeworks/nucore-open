# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::OwlApiAdapter do
  let(:user) { instance_double(User, username: "anetid") }
  subject(:adapter) { described_class.new(user) }

  describe "with a successful response" do
    let(:response) { File.expand_path("../../fixtures/owl/success.json", __dir__) }

    before do
      stub_request(:get, "https://owlstage.umass.edu/owlj/servlet/OwlPreLogin")
        .with(query: hash_including({"ID" => "anetid"}))
        .to_return(
          body: File.new(response),
          status: 200,
        )
    end

    it "is certified for BIOSAFE" do
      certificate = instance_double(ResearchSafetyCertificate, name: "BIOSAFE")
      expect(adapter).to be_certified(certificate)
    end

    it "is certified for LABSAFE" do
      certificate = instance_double(ResearchSafetyCertificate, name: "LABSAFE")
      expect(adapter).to be_certified(certificate)
    end

    it "is not certified for RANDOMSAFE" do
      certificate = instance_double(ResearchSafetyCertificate, name: "RANDOMSAFE")
      expect(adapter).not_to be_certified(certificate)
    end

    it "only calls the response once" do
      expect(described_class).to receive(:fetch).once.and_call_original
      adapter.certified? instance_double(ResearchSafetyCertificate, name: "BIOSAFE")
      adapter.certified? instance_double(ResearchSafetyCertificate, name: "LABSAFE")
      adapter.certified? instance_double(ResearchSafetyCertificate, name: "RANDOM")
    end
  end

  describe "an IP address violation" do
    let(:response) { File.expand_path("../../fixtures/owl/ip_violation.json", __dir__) }
    before do
      stub_request(:get, "https://owlstage.umass.edu/owlj/servlet/OwlPreLogin")
        .with(query: hash_including({"ID" => "anetid"}))
        .to_return(
          body: File.new(response),
          status: 200,
        )
    end

    it "raises an error" do
      expect { adapter.certified?(anything) }.to raise_error("IP security violation")
    end
  end

  describe "unable to connect" do
    before do
      stub_request(:get, "https://owlstage.umass.edu/owlj/servlet/OwlPreLogin")
        .with(query: hash_including({"ID" => "anetid"}))
        .to_timeout
    end

    it "raises an error" do
      expect { adapter.certified?(anything) }.to raise_error(Timeout::Error)
    end
  end

end
