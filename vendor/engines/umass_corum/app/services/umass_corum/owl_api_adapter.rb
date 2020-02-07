# frozen_string_literal: true

module UmassCorum

  class OwlApiAdapter

    TIMEOUT = 3

    def self.params
      {
        Server: Rails.env.production? ? "owl-ehs" : "owl-ehsstaging",
        UserType: "Student",
        fxn: "trcompleted",
        Mode: "IALSCorum", # If you need to test in development and avoid IP violations, use "IALSDummy"
      }
    end

    # Note: If you are not on the UMass VPN, both servers are inaccessible due to firewalling
    def self.host
      Rails.env.production? ? "owl.umass.edu" : "owlstage.umass.edu"
    end

    def self.fetch(netid)
      ActiveSupport::Notifications.instrument "get_owl_certifications.umass_corum" do |payload|
        payload[:emplid] = netid

        uri = URI.parse("https://#{host}/owlj/servlet/OwlPreLogin")
        uri.query = URI.encode_www_form(params.merge("ID" => netid))

        Net::HTTP.start(uri.host, uri.port, open_timeout: TIMEOUT, read_timeout: TIMEOUT, use_ssl: true) do |http|
          req = Net::HTTP::Get.new(uri)
          response = http.request(req)
          payload[:response] = response
          response.body
        end
      end
    end

    def initialize(user)
      @user = user
    end

    def certified?(certificate)
      # Email users would never exist in the external system. They must be netid
      return false if @user.email_user?

      completed_certificate_ids.include?(certificate.name)
    end

    private

    def completed_certificate_ids
      response["certifications"].map { |certification_data| certification_data["id"] }
    end

    def response
      return @response if @response

      @response = JSON.parse(self.class.fetch(@user.username))
      raise @response["error"].fetch("message") if @response["error"]

      @response
    end

  end

end
