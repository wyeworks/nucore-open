# frozen_string_literal: true

module SangerSequencing
  class BaseController < ApplicationController
    before_action :assert_sanger_enabled_for_facility

    private

    def assert_sanger_enabled_for_facility
      raise ActionController::RoutingError, "Sanger not enabled for this facility" unless current_facility.try(:sanger_sequencing_enabled?)
    end
  end
end
