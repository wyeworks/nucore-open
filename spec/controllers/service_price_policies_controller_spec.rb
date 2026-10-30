# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"
require "price_policies_controller_shared_examples"

RSpec.describe ServicePricePoliciesController do
  render_views

  before(:all) { create_users }

  it_should_behave_like PricePoliciesController, :service
end
