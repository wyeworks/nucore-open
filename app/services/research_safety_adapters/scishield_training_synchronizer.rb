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
        user_certs = {}

        # In some cases, making many requests in a row results in the API not
        # responding. Making requests in batches with sleep in between seems
        # to make the API work in most cases where this is a problem. `sleep`
        # is put first here because `api_unavailable?` will have already made
        # 10 API requests.
        users.in_batches(of: batch_size) do |user_batch|
          sleep(batch_sleep_time)

          user_batch.each do |user|
            adapter = ScishieldApiAdapter.new(user, api_client)
            retries = 0
            retry_sleep_time = batch_sleep_time

            begin
              cert_names = adapter.certified_course_names_from_api
              user_certs[user.id.to_s] = cert_names if cert_names.presence
            rescue => e
              # Sometimes the sleep between batches is not enough and failures
              # happen. Sleeping before retrying an individual request seems to
              # allow that request to succeed. Each retry sleeps 25% longer than
              # the previous try.
              if retries < retry_max
                retry_sleep_time *= 1.25
                msg = "ScishieldTrainingSynchronizer#synchronize request for user id #{user.id} failed, retrying in #{retry_sleep_time} seconds. Error: #{e.message}"

                Rails.logger.warn(msg)
                Rollbar.warn(msg) if defined?(Rollbar)

                retries += 1
                sleep(retry_sleep_time)
                retry
              else
                Rails.logger.error(e.message)
                Rollbar.error(e.message) if defined?(Rollbar)
              end
            end
          end
        end

        ScishieldTraining.transaction do
          ScishieldTraining.delete_all

          user_certs.each do |user_id, cert_names|
            trainings_added = 0

            cert_names.each do |name|
              st = ScishieldTraining.create!(user_id:, course_name: name)
              trainings_added += 1 if st.persisted?
            end

            puts "#{trainings_added} trainings added for user id #{user_id}"
          end
        rescue StandardError => e
          msg = "Rolling back transaction, ScishieldTrainingSynchronizer error: #{e.message}"

          Rails.logger.error(msg)
          Rollbar.error(msg) if defined?(Rollbar)

          raise ActiveRecord::Rollback
        end
      end
    end

    def api_unavailable?
      # Test API responses for 10 random users
      users.sample(10).map do |user|
        api_client.invalid_response?(user.email)
      end.all?
    end

    def users
      @users ||= User.active.select(ScishieldApiAdapter.user_attributes)
    end

    def api_client
      @api_client ||= ScishieldApiClient.new
    end

    def batch_size
      Settings.research_safety_adapter.scishield.batch_size
    end

    def batch_sleep_time
      Settings.research_safety_adapter.scishield.batch_sleep_time
    end

    def retry_max
      Settings.research_safety_adapter.scishield.retry_max
    end
  end

end
