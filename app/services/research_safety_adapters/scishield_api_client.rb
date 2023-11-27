# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldApiClient

    require "jwt"

    KEY = Rails.application.secrets.dig(:scishield, :key)
    KEY_ID = Rails.application.secrets.dig(:scishield, :key_id)
    PRIVATE_KEY = Rails.application.secrets.dig(:scishield, :rsa_private_key)
    API_ENDPOINT = Rails.application.secrets.dig(:scishield, :scishield_endpoint)

    def token
      return @token if @token.present?
      return nil unless keys_present?

      now = Time.current.to_i
      payload = {
        iat: now,
        exp: now + 3600,
        drupal: { uid: KEY }
      }
      rsa_private = OpenSSL::PKey::RSA.new(unescape(PRIVATE_KEY))
      @token = JWT.encode(payload, rsa_private, "RS256", { kid: KEY_ID })
    end

    # need to make sure \n gets unescaped when reading this in from ENV
    def unescape(string)
      "\"#{string}\"".undump
    end

    def keys_present?
      [KEY, KEY_ID, PRIVATE_KEY].all?(&:present?)
    end

    def certifications_for(email)
      response = training_api_request(email)
      response.body
    end

    def training_api_request(email)
      uri = URI(api_endpoint(email))
      req = Net::HTTP::Get.new(uri)
      req["accept"] = "application/json"
      req["authorization"] = "UsersJwt #{token}"
      Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    end

    def api_endpoint(email)
      "#{API_ENDPOINT}?#{training_query(email)}"
    end

    # Builds a nested query
    # We only want completed courses for each user.
    # Returns a String
    #
    # "include=course_id&filter[status]=1&filter[user][condition][operator]=%3D&filter[user][condition][path]=user_id.mail&filter[user][condition][value]=Todd.Miller%40oregonstate.edu"
    def training_query(email)
      Rack::Utils.build_nested_query(
        include: "course_id",
        filter: {
          status: 1,
          user: {
            condition: {
              path: "user_id.mail",
              operator: "=",
              value: email
            }
          }
        }
      )
    end
  end

end
