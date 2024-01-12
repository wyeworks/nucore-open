# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldApiAdapter

    attr_reader :client

    def self.user_attributes
      [:id, :email]
    end

    def initialize(user, client = ScishieldApiClient.new)
      @user = user
      @client = client
    end

    def certified?(certificate)
      certified_course_names.include?(certificate.name)
    end

    def certified_course_names
      certified_course_names_from_db.presence || certified_course_names_from_api
    end

    def certified_course_names_from_db
      ScishieldTraining.where(user_id: @user.id).map(&:course_name)
    end

    def certified_course_names_from_api
      # The "data" key should always be present with a default value of an empty array.
      # Sometimes during the retry process the "data" key is missing, which causes an error.
      if certification_data.dig("data").nil?
        # TODO: Remove this logging when the cause is better understood
        msg = "User #{@user.id} has no data in the SciShield API"
        Rollbar.error(msg) if defined?(Rollbar)
        []
      else
        certification_data["data"].map do |training_record|
          course_id = training_record["relationships"]["course_id"]["data"]["id"]
          course = certification_data["included"].select { |course| course["id"] == course_id }.first
          course.dig("attributes", "title")
        end
      end
    end

    def certification_data
      return @certification_data if @certification_data

      @certification_data = JSON.parse(client.certifications_for(@user.email))
      if @certification_data.dig("errors")
        error_message = @certification_data.dig("errors").map do |error|
          "(#{error["status"]}) #{error["title"]}: #{error["detail"]}"
        end.join("\n")
        raise error_message
      end

      @certification_data
    end

  end

end
