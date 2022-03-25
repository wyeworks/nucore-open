# frozen_string_literal: true

class ExternalServiceReceiver < ApplicationRecord

  belongs_to :external_service
  belongs_to :receiver, polymorphic: true

  validates_presence_of :external_service_id, :receiver_id, :response_data

  def show_url
    url = parsed_response_data[:show_url]
    if formio_submission?(url)
      Rails.application.routes.url_helpers.formio_submission_path(formio_url: url)
    else
      url
    end
  end

  def edit_url
    url = parsed_response_data[:edit_url]
    if formio_submission?(url)
      Rails.application.routes.url_helpers.edit_formio_submission_path(formio_url: url)
    else
      url
    end
  end

  private

  def formio_submission?(url)
    URI(url).host.try(:ends_with?, "form.io")
  end

  def parsed_response_data
    JSON.parse(response_data).symbolize_keys
  rescue TypeError, JSON::ParserError
    {}
  end

end
