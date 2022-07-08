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

      raise "#{@username} is already an external user" if user.authenticated_locally?

      user.assign_attributes(
        username: user.email,
        password: generate_new_password,
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

    private

    # Generates a secure password for a new user based on our password-complexity requirements
    def generate_new_password
      symbols = %w[! " # $ % & ' ( ) * + , - . / : ; < = > ? @ \[ \\ \] ^ _ ` { | } ~]
      chars = ("a".."z").to_a.sample(3) + ("1".."9").to_a.sample(3) + ("A".."Z").to_a.sample(3) + symbols.sample(3)

      chars.shuffle.join
    end

  end

end
