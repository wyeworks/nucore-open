# frozen_string_literal: true

module ResearchSafetyAdapters

  # This class refreshes and synchronizes the local copy of `ScishieldTraining`s
  # with the Scishield API. This will ensure the local data is up to date with
  # the API for when safety training checks are done.
  class ScishieldTrainingSynchronizer
    def synchronize
      if api_unavailable?
        msg = "Scishield API down, aborting synchronization"
        Rails.logger.error(msg)
        Rollbar.error(msg) if defined?(Rollbar)
      else
        ScishieldTraining.transaction do
          ScishieldTraining.delete_all

          users.find_each do |user|
            adapter = ScishieldApiAdapter.new(user)
            cert_names = adapter.certified_course_names_from_api
            trainings_added = 0

            cert_names.each do |cert_name|
              st = ScishieldTraining.create(user_id: user.id, course_name: cert_name)
              trainings_added += 1 if st.errors.blank?
            end

            puts "#{trainings_added} trainings added for user id #{user.id}"
          end
        rescue StandardError
          msg = "ScishieldTrainingSynchronizer error, rolling back transaction"

          Rails.logger.error(msg)
          Rollbar.error(msg) if defined?(Rollbar)

          raise ActiveRecord::Rollback
        end
      end
    end

    def api_unavailable?
      # Test API responses for 10 random users
      users.sample(10).map do |user|
        client = ScishieldApiClient.new
        response = client.training_api_request(user.email)
        http_status = response.code

        # track if http status is 5xx, 403, or 404, or not
        http_status.match?(/5|403|404/)
      end.all?
    end

    def users
      @users ||= User.active.select(ScishieldApiAdapter.user_attributes)
    end
  end

end
