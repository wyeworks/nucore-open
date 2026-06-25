# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AbilityExtension do
  subject(:ability) { Ability.new(user, facility) }
  let(:facility) { FactoryBot.create(:facility) }

  describe "granular permission user with order_management", feature_setting: { granular_permissions: true } do
    let(:user) { create(:user) }

    before do
      create(:facility_user_permission, user:, facility:, read_access: true, order_management: true)
    end

    it { is_expected.to be_allowed_to(:show_problems, SecureRooms::Occupancy) }
  end
end
