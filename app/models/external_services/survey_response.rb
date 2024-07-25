# frozen_string_literal: true

class SurveyResponse

  attr_reader :params

  def initialize(params)
    @params = params
  end

  def save!
    od = OrderDetail.find params[:receiver_id]
    external_service = ExternalService.find params[:external_service_id]

    ExternalServiceReceiver.transaction do
      receiver = ExternalServiceReceiver.find_or_initialize_by(receiver_id: od.id, external_service_id: external_service.id)
      receiver.receiver = od # must assign so receiver type is stored
      receiver.response_data = response_data
      receiver.external_id = params[:survey_id].presence
      if params[:quantity].present?
        receiver.manages_quantity = true
        od.quantity = params[:quantity].to_i
      end
      if params[:order_detail].present?
        od.assign_attributes(sanitized_order_detail_params)
      end
      receiver.save!
      od.save!
      receiver
    end
  end

  def response_data
    show_url = params[:survey_url]
    # new survey services (i.e. form.io) provide the edit URL
    # old survey services (i.e. Surveyor) have the edit URL inferred
    edit_url = params[:survey_edit_url] || "#{show_url}/take"
    { show_url: show_url, edit_url: edit_url }.to_json
  end

  def sanitized_order_detail_params
    params[:order_detail].keep_if { |k| k.starts_with?("orderDetail") }
    params[:order_detail].transform_keys! { |k| k.sub("orderDetail", "").underscore }
    params[:order_detail].permit(:note, :reference_id, :quantity)
  end

end
