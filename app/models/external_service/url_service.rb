# frozen_string_literal: true

#
# A UrlService is an +ExternalService+ that is
# accessed via HTTP/URLs.
class UrlService < ExternalService

  include Rails.application.routes.url_helpers

  #
  # Provides a URL for entering new data at this +ExternalService+
  # [_receiver_]
  #   Is the receiver of a polymorphic +ExternalServiceReceiver+
  #   relationship. Useful for providing pass-thru HTTP param data
  #   to the external service.
  def new_url(receiver, request = nil)
    sanitized_location = location.strip
    if formio_form?(sanitized_location)
      new_formio_submission_path({ formio_url: sanitized_location }.merge(additional_query_params(receiver, request)))
    else
      merge_queries(location, additional_query_params(receiver, request))
    end
  end

  def edit_url(receiver, request = nil)
    merge_queries(receiver.edit_url, additional_query_params(receiver, request))
  end

  private

  def formio_form?(url_string)
    URI(url_string).host.try(:ends_with?, "form.io")
  end

  def merge_queries(url, additional_hash)
    uri = URI(url.to_s.strip)
    query_hash = Rack::Utils.parse_query(uri.query)
    query_hash.merge!(additional_hash)
    uri.query = query_hash.to_query
    uri.to_s
  end

  def additional_query_params(receiver, request)
    query = {
      success_url: success_path(receiver, request),
      referer: referer_url(request),
      receiver_id: receiver.id,
    }

    query[:order_number] = receiver.order_number if receiver.respond_to?(:order_number)
    query[:quantity] = receiver.quantity if receiver.respond_to?(:quantity)
    query
  end

  def referer_url(request)
    "#{request.protocol}#{request.host_with_port}#{request.fullpath}" if request
  end

  def success_path(receiver, request)
    params = {
      facility_id: receiver.product.facility.url_name,
      service_id: receiver.product.url_name,
      external_service_id: id,
      receiver_id: receiver.id,
    }
    params.merge!(host: request.host, port: request.port, protocol: request.protocol) if request
    complete_survey_url(params)
  end

end
