# frozen_string_literal: true

namespace :sanger_sequencing do
  desc "Creates default Core Primers for Sanger enabled facilities without primers"
  task create_default_primers: :environment do
    Facility.where(sanger_sequencing_enabled: true).find_each do |facility|
      next unless facility.sanger_sequencing_primers.empty?

      puts "Creating default Primers for #{facility}"

      SangerSequencing::Primer.insert_all(
        SangerSequencing::Primer.default_list.map do |name|
          { name:, facility_id: facility.id }
        end
      )
    end
  end
end
