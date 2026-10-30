# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::ArchivedProductRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
    )
  end
  let(:card_user) { build :user }
  let(:card_reader) { build :card_reader, secure_room: }

  subject(:result) { rule.call }

  context "room is archived" do
    let(:secure_room) { build :secure_room, is_archived: true }

    it { is_expected.to have_result_code(:deny) }
  end

  context "room is not archived" do
    let(:secure_room) { build :secure_room, is_archived: false }

    it { is_expected.to have_result_code(:pass) }
  end
end
