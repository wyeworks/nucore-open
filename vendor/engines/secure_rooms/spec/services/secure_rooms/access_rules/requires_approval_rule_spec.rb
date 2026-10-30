# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::RequiresApprovalRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
    )
  end
  let(:card_user) { create :user }
  let(:card_reader) { build :card_reader, secure_room: }

  subject(:result) { rule.call }

  context "room requires approval" do
    let(:secure_room) { create :secure_room, requires_approval: true }

    context "user is on list" do
      before { ProductUser.create(product: secure_room, user: card_user, approved_by: Time.current.to_i) }

      it { is_expected.to have_result_code(:pass) }
    end

    context "user is not on list" do
      it { is_expected.to have_result_code(:deny) }
    end
  end
end
