# frozen_string_literal: true

RSpec.shared_context "external service" do

  let(:external_service_passer) { create :external_service_passer, active: true }
  let(:external_service) { external_service_passer.external_service }
  let(:external_service_receiver) { create :external_service_receiver, external_service: external_service }

  let :params_hash do
    {
      receiver_id: external_service_receiver.receiver.id,
      external_service_id: external_service.id,
      external_service_passer_id: external_service_passer.id,
      quantity: external_service_receiver.receiver.quantity,
      survey_id: "CX-12345",
      survey_url: "http://survey.local/show",
      survey_edit_url: "http://survey.local/edit",
    }
  end

  let(:params) { ActionController::Parameters.new(params_hash) }
end
