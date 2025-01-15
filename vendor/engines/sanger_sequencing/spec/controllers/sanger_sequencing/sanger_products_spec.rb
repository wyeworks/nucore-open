# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe SangerSequencing::SangerProductsController do
  let(:facility) { create(:setup_facility, sanger_sequencing_enabled: true) }
  let(:service) { create(:setup_service, facility:, sanger_sequencing_enabled: true) }
  let(:user) { create(:user, :facility_administrator, facility:) }

  before do
    sign_in user

    @params = { facility_id: facility.url_name, service_id: service.url_name }
  end

  shared_examples "creates a sanger product if needed" do
    it "creates a sanger product if needed" do
      expect { do_request }.to(
        change do
          service.reload.sanger_product
        end.from(nil).to(SangerSequencing::SangerProduct)
      )
    end
  end

  describe "show" do
    before do
      @method = :get
      @action = :show
    end

    include_examples "creates a sanger product if needed"
  end

  describe "edit" do
    before do
      @method = :get
      @action = :edit
    end

    include_examples "creates a sanger product if needed"
  end

  describe "update" do
    before do
      @method = :put
      @action = :update
      @params[:sanger_sequencing_sanger_product] = { group: "default" }
    end

    include_examples "creates a sanger product if needed"

    it "updates the sanger product" do
      sanger_product_json = {
        "needs_primer" => true, "group" => "fragment"
      }
      @params[:sanger_sequencing_sanger_product] = sanger_product_json

      service.create_sanger_product

      expect { do_request }.to(
        change do
          service.reload.sanger_product.as_json(only: %i[needs_primer group])
        end.from(
          { "needs_primer" => false, "group" => "default" }
        ).to(
          sanger_product_json
        )
      )
    end
  end
end
