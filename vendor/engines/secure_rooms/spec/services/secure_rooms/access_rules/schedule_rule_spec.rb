# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccessRules::ScheduleRule do
  let(:user) { create(:user) }
  let(:secure_room) { create(:secure_room) }
  let(:card_reader) { build(:card_reader, secure_room:) }
  let!(:product_user) { ProductUser.create!(product: secure_room, user_id: user.id, approved_by: 0) }

  subject(:result) do
    described_class.new(
      user,
      card_reader,
    ).call
  end

  describe "there are no schedule rules" do
    it { is_expected.to be_denied }
  end

  describe "there is a schedule rule", :timecop_freeze do
    # Factory default to 9-5 every day
    let!(:schedule_rule) { secure_room.schedule_rules.create(attributes_for(:schedule_rule)) }

    describe "and it is inside the rule" do
      let(:now) { Time.zone.local(2017, 4, 5, 12, 0) }

      it { is_expected.to be_pass }
    end

    describe "and it is outside the rule" do
      let(:now) { Time.zone.local(2017, 4, 5, 19, 0) }
    end

    describe "and there are scheduling groups" do
      let!(:schedule_group) { create(:product_access_group, product: secure_room, schedule_rules: [schedule_rule]) }
      let(:now) { Time.zone.local(2017, 4, 5, 12, 0) }

      describe "the user is not part of the group" do
        it { is_expected.to be_denied }
      end

      describe "and the user is part of the group" do
        before do
          product_user.update(product_access_group: schedule_group)
        end

        it { is_expected.to be_pass }
      end
    end
  end
end
