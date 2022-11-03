# frozen_string_literal: true

module ResearchSafetyAdapters

  class ScishieldApiAdapter

    def initialize(user)
      @user = user
    end

    def client
      @client ||= ScishieldApiClient.new
    end

    def certified?(certificate)
      certified_course_names.include?(certificate.name)
    end

    def certified_course_names
      certification_data["data"].map do |training_record|
        course_id = training_record["relationships"]["course_id"]["data"]["id"]
        course = certification_data["included"].select { |course| course["id"] == course_id }.first
        course.dig("attributes", "title")
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
