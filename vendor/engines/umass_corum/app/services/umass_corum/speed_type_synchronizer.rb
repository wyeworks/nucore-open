module UmassCorum

  class SpeedTypeSynchronizationError < StandardError

    attr_reader :speed_type_account_id

    def initialize(speed_type_account_id)
      @speed_type_account_id = speed_type_account_id
      super(message)
    end

    def message
      "No ApiSpeedType found for SpeedTypeAccount id: #{speed_type_account_id}"
    end

  end

  class SpeedTypeSynchronizer

    attr_accessor :speed_type_account, :logger

    def initialize(speed_type_account, logger: Rails.logger)
      self.speed_type_account = speed_type_account
      self.logger = logger
    end

    def self.run!(logger: Rails.logger)
      total_updated = 0
      UmassCorum::SpeedTypeAccount.all.find_each do |speed_type_account|
        updater = new(speed_type_account, logger: logger)
        total_updated += 1 if updater.run
      end
      logger.info("#{total_updated} SpeedTypeAccounts have been updated.")
    end

    def run
      if api_speed_type.nil?
        # Just need an error for logging/Rollbar
        exception = SpeedTypeSynchronizationError.new(speed_type_account.id)
        ActiveSupport::Notifications.instrument("background_error", exception: exception)
        false
      elsif needs_update?
        original_exp_date = speed_type_account.expires_at.strftime('%m/%d/%Y')
        speed_type_account.update(expires_at: new_exp_date)
        logger.info("ID ##{speed_type_account.id}, expires_at changed from #{original_exp_date} to #{speed_type_account.formatted_expires_at}")
        true
      end
    end

    def api_speed_type
      @api_speed_type ||= UmassCorum::ApiSpeedType.find_by(speed_type: speed_type_account.account_number)
    end

    # SpeedTypeAccounts require a value for the expires_at column.
    # The default is 100 years from created_at.
    # For the purpose of comparison with other date fields,
    # an expires_at date far in the future should be treated as nil.
    def needs_update?
      if api_speed_type.project_id.present? && api_speed_type.project_end_date.present?
        api_speed_type.project_end_date != speed_type_account.expires_at
      elsif api_speed_type.date_removed.present?
        api_speed_type.date_removed != speed_type_account.expires_at
      else
        speed_type_account.expires_at <= 75.years.from_now
      end
    end

    # SpeedTypeAccount#expires_at is required, use the default if date_removed is nil
    def new_exp_date
      if api_speed_type.project_id.present? && api_speed_type.project_end_date.present?
        api_speed_type.project_end_date
      elsif api_speed_type.date_removed
        api_speed_type.date_removed
      else
        speed_type_account.class.default_nil_exp_date
      end
    end

  end

end
