# frozen_string_literal: true

require "rails_helper"

RSpec.describe UrlService do

  let(:url_service) do
    described_class.create(
      location: "http://www.survey.com/survey1",
      default_url_options: { host: "defaulthost", port: nil },
    )
  end

  let(:service) { create :setup_service }
  let(:order) { create :setup_order, product: service }
  let(:order_detail) { create :order_detail, order: order, product: service, quantity: 3 }

  let(:facility) { order_detail.product.facility }
  let(:product) { order_detail.product }

  let(:query_hash) { Rack::Utils.parse_query(uri.query) }
  let(:uri) { URI(url_service.new_url(order_detail)) }

  it "uses the service's location as its base" do
    expect(uri.to_s).to start_with("http://www.survey.com/survey1?")
  end

  describe "with a request" do
    let(:request) { double(host_with_port: "realdomain:8080", fullpath: "/mysite", host: "realdomain", port: 8080, protocol: "https://") }
    let(:uri) { URI(url_service.new_url(order_detail, request)) }

    it "sets the correct receiver id" do
      expect(query_hash["receiver_id"]).to eq(order_detail.id.to_s)
    end

    it "sets the quantity" do
      expect(query_hash["quantity"]).to eq("3")
    end

    it "sets the order number" do
      expect(query_hash["order_number"]).to eq(order_detail.to_s)
    end

    it "sets the correct success url" do
      expect(query_hash["success_url"])
        .to eq("https://realdomain:8080/#{I18n.t('facilities_downcase')}/#{facility.url_name}/services/#{product.url_name}/surveys/#{url_service.id}/complete?receiver_id=#{order_detail.id}")
    end

    it "returns a blank referer" do
      expect(query_hash["referer"]).to eq("https://realdomain:8080/mysite")
    end
  end

  describe "without a request" do
    it "sets the correct success url" do
      expect(query_hash["success_url"])
        .to eq("http://defaulthost/#{I18n.t('facilities_downcase')}/#{facility.url_name}/services/#{product.url_name}/surveys/#{url_service.id}/complete?receiver_id=#{order_detail.id}")
    end

    it "returns a blank referer" do
      expect(query_hash["referer"]).to be_blank
    end

    describe "when the location already has a ? in it" do
      before { url_service.location = "http://www.survey.com/survey1?q=true&other=false" }

      it "sets the currect uri" do
        expect(uri.to_s).to start_with("http://www.survey.com/survey1?")
        expect(query_hash).to include(
          "q" => "true",
          "other" => "false",
          "receiver_id" => order_detail.id.to_s,
        )
      end
    end

    context "for a Form.IO form" do
      before { url_service.location = "https://nucore-development-12ea0e74.form.io/labitsupport" }

      it "returns a URL for a new formio submission" do
        expect(uri.to_s).to start_with("/formio/submission/new")
      end

      it "includes the location as a formio_url parameter" do
        expect(query_hash).to include("formio_url" => url_service.location)
      end
    end
  end

  describe "edit_url" do
    let(:edit_url) { url_service.edit_url(order_detail) }
    let(:query_hash) { Rack::Utils.parse_query(URI(edit_url).query) }

    describe "when the url already has a ?" do
      before { allow(order_detail).to receive(:edit_url).and_return("http://www.survey.com/surveys/edit?id=123") }

      it "sets the query string correctly if the link already has a ?" do
        expect(edit_url).to start_with("http://www.survey.com/surveys/edit?")
        expect(query_hash).to include(
          "id" => "123",
          "receiver_id" => order_detail.id.to_s,
        )
      end
    end

    describe "when the URL has some whitespace around it" do
      before { allow(order_detail).to receive(:edit_url).and_return("\thttp://www.survey.com/surveys/edit?id=123") }

      it "sets the query string correctly if the link already has a ?" do
        expect(edit_url).to start_with("http://www.survey.com/surveys/edit?")
        expect(query_hash).to include(
          "id" => "123",
          "receiver_id" => order_detail.id.to_s,
        )
      end
    end

    describe "when the url is blank (should be prevented by validations)" do
      before { allow(order_detail).to receive(:edit_url).and_return(nil) }

      it "treats it as a relative path with a receiver_id" do
        expect(edit_url).to start_with("?")
        expect(query_hash).to include(
          "receiver_id" => order_detail.id.to_s,
        )
      end
    end
  end

  describe "#new_url" do
    context "when the location contains invalid space characters" do
      before do
        url_service.location = " \thttps://nucore-staging.northwestern.edu/acgt/submissions/new"
      end

      it "does not raise an error" do
        expect(url_service.new_url(order_detail)).to be_a(String)
      end
    end
  end
end
