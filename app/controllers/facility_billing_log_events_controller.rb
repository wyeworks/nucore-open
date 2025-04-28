# frozen_string_literal: true

class FacilityBillingLogEventsController < ApplicationController
  before_action :authenticate_user!
  before_action { authorize! :manage_billing, Facility.cross_facility }

  layout "two_column"

  include ListBillingLogEvents
end
