# frozen_string_literal: true

namespace :sanger_sequencing do
  desc "Creates default Core Primers for a Facility"
  task :create_default_primers, [:url_name] => :environment do |_task, args|
    facility_url_name = args[:url_name]

    if facility_url_name.blank?
      puts "Facility url_name is a required argument"
      exit 1
    end

    facility_id = Facility.find_by!(url_name: facility_url_name).id

    SangerSequencing::Primer.insert_all(
      SangerSequencing::Primer.default_list.map do |name|
        { name:, facility_id: }
      end
    )
    puts "Created default Primers"
  end
end
