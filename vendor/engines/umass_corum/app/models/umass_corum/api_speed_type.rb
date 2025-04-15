# frozen_string_literal: true

module UmassCorum

  # The columns of this class match the keys in the JSON response we get from
  # the API.
  class ApiSpeedType < ApplicationRecord
    belongs_to :speed_type_account,
               foreign_key: :account_number,
               primary_key: :speed_type,
               optional: true,
               inverse_of: :api_speed_type

    validates :speed_type, presence: true, uniqueness: { case_sensitive: false }
    validates :active, inclusion: [true, false]

    # Returns either a new record if it does not already exist in the database
    # or the existing record. All of the attributes will have been assigned with
    # possibly new values from the API, but the changes have not been persisted.
    def self.find_or_initialize_from_api(speed_type)
      model = find_or_initialize_by(speed_type: speed_type)
      results = fetch(speed_type)

      model.assign_attributes(results.slice(*valid_attribute_names))
      model
    end

    def self.valid_attribute_names
      attribute_names + ["class"]
    end

    def self.fetch(speed_type)
      ActiveSupport::Notifications.instrument "get_speed_type.umass_corum" do |payload|
        uri = URI.parse(details.endpoint)

        Net::HTTP.start(uri.host, uri.port, open_timeout: 3, read_timeout: 3, use_ssl: true) do |http|
          req = Net::HTTP::Get.new("#{uri.request_uri}/#{speed_type}")
          req.basic_auth(*credentials)
          req["Accept"] = "application/json"
          response = http.request(req)

          payload[:speed_type] = speed_type
          payload[:response] = response

          JSON.parse(response.body)
        end
      end
    end

    # "class" is a key we get from the API, but it's a reserved word in
    # Ruby and confuses ActiveRecord as a column name
    def class=(value)
      self.clazz = value
    end

    def self.credentials
      [
        details.username,
        details.password,
      ]
    end

    def self.details
      OpenStruct.new(Rails.application.secrets.dig(:umass, :speed_type_api))
    end

  end

end
