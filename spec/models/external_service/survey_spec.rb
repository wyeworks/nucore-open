# frozen_string_literal: true

require "rails_helper"

RSpec.describe Survey do
  include_context "external service"

  subject(:survey) { described_class.new external_service_passer.passer, params }

  it "has a service accessor" do
    expect(survey.service).to eq external_service_passer.passer
  end

  it "has a params accessor" do
    expect(survey.params).to eq params
  end

  it "sets active to false on the currently active survey" do
    expect(external_service_passer).to be_active
    survey.deactivate_current
    expect(external_service_passer.reload).to_not be_active
  end

  it "finds the external service passer" do
    expect(survey.external_service_passer).to eq external_service_passer
  end

  it "makes the external service passer active" do
    external_service_passer.update_attribute :active, false
    expect(survey).to receive :deactivate_current
    survey.activate
    expect(external_service_passer.reload).to be_active
  end

  it "makes the external service passer inactive" do
    survey.deactivate
    expect(external_service_passer.reload).to_not be_active
  end
end
