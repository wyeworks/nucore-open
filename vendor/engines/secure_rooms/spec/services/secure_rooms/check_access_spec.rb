# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::CheckAccess, type: :service do
  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price) }

  context "with a single deny rule" do
    let(:card_user) { build(:user) }
    let(:card_reader) { build(:card_reader) }

    let(:rules) { [SecureRooms::AccessRules::DenyAllRule] }
    subject(:check_access) { described_class.new(rules) }

    it "calls the rule" do
      expect_any_instance_of(SecureRooms::AccessRules::DenyAllRule).to receive(:evaluate)
      check_access.authorize(card_user, card_reader)
    end
  end

  describe "with default rules" do
    subject(:verdict) { described_class.new.authorize(card_user, card_reader) }

    let(:card_reader) { build(:card_reader, secure_room:) }
    let(:exit_card_reader) { build(:card_reader, :exit, secure_room:) }

    context "when a user is not present" do
      let(:card_user) { nil }
      it { is_expected.to be_denied }
    end

    describe "a global admin" do
      let(:card_user) { build(:user, :administrator) }

      describe "entry" do
        it { is_expected.to be_denied }
      end

      describe "exit" do
        let(:card_reader) { exit_card_reader }
        it { is_expected.to be_denied }
      end
    end

    describe "a facility operator" do
      let(:card_user) { create(:user, :staff, facility: secure_room.facility) }

      it { is_expected.to be_granted }

      describe "archived room" do
        before { secure_room.is_archived = true }
        it { is_expected.to be_granted }
      end
    end

    describe "a user without any accounts" do
      let(:card_user) { create(:user) }

      describe "the user is on the access list" do
        before { secure_room.product_users.create!(user: card_user, approved_by: 0) }

        describe "and inside the schedule rules", :time_travel do
          let(:now) { Time.zone.local(2016, 5, 15, 12, 0) }
          it "is denied for the right reason" do
            expect(verdict).to be_denied
            expect(verdict.reason).to include("no valid accounts")
          end
        end
      end
    end

    describe "a normal user" do
      let(:card_user) { create(:user) }
      let(:account) { create(:nufs_account, :with_account_owner, owner: card_user) }

      before do
        create(:account_price_group_member, account:, price_group: PriceGroup.base)
      end

      describe "the product is archived" do
        before { secure_room.is_archived = true }
        it "is denied for the right reason" do
          expect(verdict).to be_denied
          expect(verdict.reason).to include("archived")
        end
      end

      describe "the user is not on the access list" do
        it "is denied for the right reason" do
          expect(verdict).to be_denied
          expect(verdict.reason).to include("access list")
        end

        describe "and is trying to leave the room" do
          let(:card_reader) { exit_card_reader }

          it "is denied exiting as well" do
            expect(verdict).to be_denied
            expect(verdict.reason).to include("access list")
          end
        end
      end

      describe "the user is on the access list" do
        before { secure_room.product_users.create!(user: card_user, approved_by: 0) }

        describe "and inside the schedule rules", :time_travel do
          let(:now) { Time.zone.local(2016, 5, 15, 12, 0) }
          it { is_expected.to be_pending }
        end

        describe "but it is outside the schedule rules", :time_travel do
          let(:now) { Time.zone.local(2016, 5, 15, 0, 0) }
          describe "entering the room" do
            it "is denied for the right reason" do
              expect(verdict).to be_denied
              expect(verdict.reason).to include("schedule group")
            end
          end

          describe "exiting the room" do
            let(:card_reader) { exit_card_reader }

            it { is_expected.to be_granted }
          end
        end
      end
    end
  end
end
