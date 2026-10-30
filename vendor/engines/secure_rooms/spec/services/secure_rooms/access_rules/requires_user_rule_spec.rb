# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::RequiresUserRule, type: :service do
  let(:secure_room) { build :secure_room }
  let(:card_reader) { build :card_reader, secure_room: }
  let(:rule) { described_class.new(user, card_reader) }

  subject(:result) { rule.call }

  context "when a user is present" do
    let(:user) { build :user }

    it { is_expected.to have_result_code(:pass) }
  end

  context "when a user is not present" do
    let(:user) { nil }

    it { is_expected.to have_result_code(:deny) }
  end
end
