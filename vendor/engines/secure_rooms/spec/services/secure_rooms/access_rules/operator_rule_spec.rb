# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::OperatorRule, type: :service do
  let(:rule) do
    described_class.new(
      card_user,
      card_reader,
    )
  end
  let(:card_reader) { build(:card_reader) }
  let(:secure_room) { card_reader.secure_room }
  let(:facility) { secure_room.facility }

  subject(:response) { rule.call }

  context "user is facility operator" do
    let(:card_user) { create(:user, :facility_administrator, facility:) }

    it { is_expected.to have_result_code(:grant) }
  end

  context "user is not an operator" do
    let(:card_user) { create(:user) }

    it { is_expected.to have_result_code(:pass) }
  end

  describe "a global admin" do
    let(:card_user) { create(:user, :administrator) }

    it { is_expected.to have_result_code(:pass) }

    describe "and also an operator of the facility" do
      before { card_user.user_roles.create!(role: UserRole::FACILITY_DIRECTOR, facility:) }

      it { is_expected.to have_result_code(:grant) }
    end
  end

  describe "an account administrator" do
    let(:card_user) { create(:user, :account_manager) }

    it { is_expected.to have_result_code(:pass) }

    describe "and also an operator of the facility" do
      before { card_user.user_roles.create!(role: UserRole::FACILITY_DIRECTOR, facility:) }

      it { is_expected.to have_result_code(:grant) }
    end
  end
end
