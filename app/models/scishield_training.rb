# frozen_string_literal: true

# This model is used as a cache for Scishield trainings, the
# research_safety_adapters:scishield:synchronize_training rake task can be used
# to synchronize it with the Scishield API, this rake task should be setup as a
# cron job for any school using SciShield. ResearchSafetyAdapters::ScishieldApiAdapter
# checks this model before falling back to check with the Scishield API, allowing
# safety training checks to work even when the Scishield API is down
class ScishieldTraining < ApplicationRecord
  validates_presence_of :user_id, :course_name
end
