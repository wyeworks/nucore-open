module UmassCorum

  class SpeedTypeBackfillError < StandardError

    attr_reader :speed_type_account_id

    def initialize(speed_type_account_id)
      @speed_type_account_id = speed_type_account_id
      super(message)
    end

    def message
      "No ApiSpeedType found for SpeedTypeAccount id: #{speed_type_account_id}"
    end

  end

  class SpeedTypeBackfiller

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
        exception = SpeedTypeBackfillError.new(speed_type_account.id)
        logger.info(exception.message)
        false
      else
        logger.info("ID ##{speed_type_account.id}, HR Account Code: #{api_speed_type.hr_acct_cd}, Set ID: #{api_speed_type.setid}, Speed Chart Description: #{api_speed_type.speedchart_desc}")

        api_speed_type.save!
      end
    end

    def api_speed_type
      @api_speed_type ||= UmassCorum::ApiSpeedType.find_or_initialize_from_api(speed_type_account.account_number)
    end

  end

end
