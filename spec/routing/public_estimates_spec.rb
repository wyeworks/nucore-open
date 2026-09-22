# frozen_string_literal: true

require "rails_helper"

RSpec.describe "public estimate route", feature_setting: { show_estimates_option: true } do
  context "when the feature is enabled", feature_setting: { public_estimates: true, reload_routes: true } do
    it "defines the public estimates route" do
      expect(get: "/estimate").to be_routable
    end
  end

  context "when the feature is disabled", feature_setting: { public_estimates: false, reload_routes: true } do
    it "does not define the public estimates route" do
      expect(get: "/estimate").not_to be_routable
    end
  end
end
