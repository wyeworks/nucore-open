# frozen_string_literal: true

# rails umass_corum:reset_als_sequence should be run on July 1 as a cron job
namespace :umass_corum do
  desc "Drop AlsSequenceNumbers and recreate it to reset the ALS sequence"
  task reset_als_sequence: :environment do
    ActiveRecord::Base.connection.truncate(:umass_corum_als_sequence_numbers)
  end

  desc "ONLY RUN ONCE: Populate als_number fields before the generator was created."
  task backfill_empty_als_numbers: :environment do
    Journal.where("als_number is NULL").each do |journal|
      journal.update(als_number: "ALS#{format('%03d', journal.id % 1000)}")
    end  
  end
end
