# frozen_string_literal: true

module Users

  class ConvertInternalToExternalUser

    attr_reader :logger

    def initialize(username, dryrun: false, logger: Rails.logger)
      @username = username
      @dryrun = dryrun
      @logger = logger
    end

    def convert!
      user = User.find_by!(username: @username)

      raise "#{@username} is already an external user" if user.email_user?

      user.assign_attributes(
        username: user.email,
        password: SecureRandom.hex,
      )

      logger.info("Changing #{user.changes}")
      if @dryrun
        logger.info "Dry run"
      else
        user.save!
        logger.info "User updated!"
        logger.info "The user may use Forgot Password to create a new password"
      end
    end

  end

end
