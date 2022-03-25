# frozen_string_literal: true

class Survey

  attr_reader :service, :params

  def initialize(service, params)
    @service = service
    @params = params
  end

  def activate
    deactivate_current
    external_service_passer.update_attribute :active, true
  end

  def deactivate
    external_service_passer.update_attribute :active, false
  end

  def deactivate_current
    old_active = service.external_service_passers.find_by(active: true)
    old_active.update_attribute(:active, false) if old_active
  end

  def external_service_passer
    esp_id = params[:external_service_passer_id]
    @external_service_passer ||= service.external_service_passers.find(esp_id)
  end

end
