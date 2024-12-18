# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScheduleRulesController, :aggregate_failures do
  it_behaves_like "A product supporting ScheduleRulesController", :instrument
end
