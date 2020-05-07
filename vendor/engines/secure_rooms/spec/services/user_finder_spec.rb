# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserFinder do
  describe ".search" do
    it "finds users by card_number" do
      card_number = SecureRandom.hex(8)
      user = FactoryBot.create(:user, card_number: card_number)
      found_users = UserFinder.search(card_number, nil)
      expect(found_users).to include(user)
    end
  end
end
