# frozen_string_literal: true

namespace :umass_corum do
  desc "Synchronize expiration between SpeedTypeAccount and ApiSpeedType tables"
  task synchronize_speedtype_accounts: :environment do
    UmassCorum::SpeedTypeSynchronizer.run!
  end

  task backfill_speedtype_accounts: :environment do
    UmassCorum::SpeedTypeBackfiller.run!
  end
end
