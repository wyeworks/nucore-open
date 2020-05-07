# frozen_string_literal: true

class Service < Product

  has_many :service_price_policies, foreign_key: :product_id
  has_many :external_service_passers, as: :passer
  has_many :external_services, through: :external_service_passers

  validates_presence_of :initial_order_status_id

  def active_survey
    active = external_service_passers.joins(:external_service)
                                     .where("active = 1 AND external_services.type = ?", UrlService.name)
                                     .first

    active ? active.external_service : nil
  end

  # returns true if there is at least 1 active survey; false otherwise
  def active_survey?
    !active_survey.blank?
  end

  # returns true if there is an active template... false otherwise
  def active_template?
    stored_files.template.count > 0
  end

  def requires_merge?
    active_survey? || active_template?
  end

end
