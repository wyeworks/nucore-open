# frozen_string_literal: true

require "rails_helper"

RSpec.describe SurveyResponse do
  include_context "external service"

  let :deserialized_response_data do
    {
      show_url: params[:survey_url],
      edit_url: params[:survey_edit_url],
    }
  end

  subject(:survey_response) { described_class.new params }

  it "has a params accessor" do
    expect(survey_response.params).to eq params
  end

  it "gives a String of URL JSON" do
    expect(survey_response.response_data).to eq deserialized_response_data.to_json
  end

  it "provides a Surveyor edit URL if an edit URL is not given" do
    params[:survey_edit_url] = nil
    deserialized_response_data[:edit_url] = "#{params[:survey_url]}/take"
    expect(survey_response.response_data).to eq deserialized_response_data.to_json
  end

  it "creates an external service receiver" do
    expect { survey_response.save! }.to change { ExternalServiceReceiver.count }.by 1
    esr = ExternalServiceReceiver.last
    expect(esr.receiver).to eq external_service_receiver.receiver
    expect(esr.external_service).to eq external_service
    expect(esr.response_data).to eq deserialized_response_data.to_json
  end

  it "saves the order detail" do
    od = external_service_receiver.receiver
    expect(OrderDetail).to receive(:find).and_return od
    expect(od).to receive :save!
    survey_response.save!
  end

  it "reuses existing ExternalServiceReceivers" do
    expect do
      survey_response.save!
      survey_response.save!
    end.to change { ExternalServiceReceiver.count }.by 1
  end

  it "updates the response_data if it has changed" do
    new_survey_url = "http://yippee.kid"

    expect do
      receiver = survey_response.save!
      expect(receiver.show_url).to_not eq new_survey_url
      params[:survey_url] = new_survey_url
      receiver = described_class.new(params).save!
      expect(receiver.show_url).to eq new_survey_url
    end.to change { ExternalServiceReceiver.count }.by 1
  end

  it "stores the survey_id as the external_id" do
    receiver = survey_response.save!
    expect(receiver.external_id).to eq params[:survey_id]
  end

  describe "quantity updates" do
    let(:order_detail) { external_service_receiver.receiver }

    it "updates the receiver quantity" do
      params[:quantity] += 3
      expect_any_instance_of(OrderDetail)
        .to receive("quantity=".to_sym).with(params[:quantity]).and_call_original
      receiver = survey_response.save!
      expect(receiver.receiver.quantity).to eq params[:quantity]
    end

    it "does not change the quantity if no quantity is given" do
      params[:quantity] = nil
      quantity = order_detail.quantity
      expect_any_instance_of(OrderDetail).to_not receive "quantity=".to_sym
      receiver = survey_response.save!
      expect(receiver.receiver.quantity).to eq quantity
    end

    it "locks the quantity for order if there is a quantity param" do
      params[:quantity] = order_detail.quantity
      expect { survey_response.save! }
        .to change { order_detail.reload.quantity_locked_by_survey? }
        .to(true)
    end

    it "does not lock the quantity for order detail if no quantity" do
      params[:quantity] = nil
      expect { survey_response.save! }
        .not_to change { order_detail.reload.quantity_locked_by_survey? }
        .from(false)
    end

    it "does not lock the quantity for order detail if no quantity" do
      params.delete(:quantity)
      expect { survey_response.save! }
        .not_to change { order_detail.reload.quantity_locked_by_survey? }
        .from(false)
    end
  end

  describe "order detail updates" do
    let(:order_detail) { external_service_receiver.receiver }

    it "updates only the receiver note, reference ID, and quantity from form data" do
      params[:order_detail] = {
        "orderDetailQuantity" => "5",
        "orderDetailReferenceId" => "123",
        "orderDetailNote" => "note",
        "orderDetailOrderStatus" => "Complete",
        "otherKindOfNote" => "this note is not stored",
      }

      expect { survey_response.save! }.to change { order_detail.reload.note }.to("note")
        .and change { order_detail.reload.reference_id }.to("123")
        .and change { order_detail.reload.quantity }.to(5)
      expect(order_detail.reload.order_status).to eq nil
    end

    it "does not change the note, reference ID, and quantity when not present" do
      params[:order_detail] = {}
      params[:quantity] = nil
      expect_any_instance_of(OrderDetail).to_not receive "quantity=".to_sym
      expect_any_instance_of(OrderDetail).to_not receive "note=".to_sym
      expect_any_instance_of(OrderDetail).to_not receive "reference_id=".to_sym
      expect { survey_response.save! }.not_to change { order_detail.reload }
    end

    it "updates quantity when order_detail params not present" do
      params[:order_detail] = {}
      params[:quantity] += 2
      expect { survey_response.save! }.to change { order_detail.reload.quantity }
    end
  end

end
