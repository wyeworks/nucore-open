# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProductAccessGroupsController, :aggregate_failures do
  it_behaves_like "A product supporting ProductAccessGroupsController", :instrument
end
