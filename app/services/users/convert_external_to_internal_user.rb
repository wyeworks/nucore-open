# frozen_string_literal: true

module Users

  class ConvertExternalToInternalUser

    attr_reader :logger

    class DefaultLookup
      def call(username)
        User.new(username: username)
      end
    end

    def initialize(email, netid, lookup: DefaultLookup.new, dryrun: false, logger: Rails.logger)
      @netid = netid
      @email = email
      @lookup = lookup
      @logger = logger
      @dryrun = dryrun
    end

    def convert!
      existing_user = User.find_by!(email: @email)
      raise "Is already an internal user" unless existing_user.email_user?

      existing_user.assign_attributes(find_attributes)

      # Clear out password so they can no longer log in
      existing_user.assign_attributes(encrypted_password: nil, password_salt: nil)
      logger.info "Changing: #{existing_user.changes}"
      if @dryrun
        logger.info "Dry run"
      else
        existing_user.save!
        logger.info "User updated!"
      end
    end

    private

    def find_attributes
      new_user_details = @lookup.call(@netid)
      raise "NetID/username #{@netid} not found in directory" unless new_user_details

      new_user_details.attributes.select { |_k, v| v.present? }
    end

  end

end
