# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::HolidayAccessRule do
  let(:user) { create(:user) }
  let(:secure_room) { create(:secure_room, restrict_holiday_access: true) }
  let(:card_reader) { build(:card_reader, secure_room: secure_room) }
  let!(:product_user) { ProductUser.create!(product: secure_room, user_id: user.id, approved_by: 0) }

  subject(:result) do
    described_class.new(
      user,
      card_reader,
    ).call
  end

  describe "today is not a holiday" do
    context "user is not in an approved group" do
      it { is_expected.to be_pass }
    end
  end

  describe "today is a holiday" do
    let!(:holiday) { Holiday.create(date: Time.current) }

    context "user is not in an approved group" do
      it { is_expected.to be_denied }

      context "exiting" do
        let(:card_reader) { build(:card_reader, :exit, secure_room: secure_room) }

        it { is_expected.to be_pass }
      end
    end

    context "user is in an approved group" do
      let!(:product_access_group) { create(:product_access_group, allow_holiday_access: true, product: secure_room) }
      let!(:product_user) { ProductUser.create!(product: secure_room, user_id: user.id, approved_by: 0, product_access_group: product_access_group) }

      it { is_expected.to be_pass }
    end
  end

end
