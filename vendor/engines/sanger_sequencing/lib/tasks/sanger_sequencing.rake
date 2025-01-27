# frozen_string_literal: true

namespace :sanger_sequencing do
  task create_default_primers: :environment do
    log "Creating default Primers"
    SangerSequencing::Primer.insert_all(
      SangerSequencing::Primer.default_list.map do |name|
        { name: }
      end
    )
  end
end
