# frozen_string_literal: true

namespace :research_safety_adapters do
  namespace :scishield do
    desc "Synchronize Scishield trainings with the Scishield API"
    task synchronize_training: :environment do |_t, _args|
      ResearchSafetyAdapters::ScishieldTrainingSynchronizer.new.synchronize
    end
  end
end
