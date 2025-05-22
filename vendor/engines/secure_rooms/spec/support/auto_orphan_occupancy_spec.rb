# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AutoOrphanOccupancy, :time_travel do
  let(:action) { described_class.new }

  let(:secure_room) { create(:secure_room, :with_schedule_rule, :with_base_price) }
  let(:card_reader) { create(:card_reader, secure_room: secure_room, ingress: true) }
  let(:user) { create(:user, card_number: "123456") }
  let(:account) { create(:nufs_account, :with_account_owner, owner: user) }

  let(:order) { create(:order, :purchased, account: account, created_by_user: user, user: user, facility: secure_room.facility) }
  let(:order_detail) { order.order_details.create(attributes_for(:order_detail, account: account, product: secure_room)) }

  before { secure_room.product_users.create!(user: user, approved_by: 0) }

  describe "#perform" do
    context "with a very long-running occupancy" do
      let(:event) { create :event, :successful, occurred_at: 3.days.ago, card_reader: card_reader, user: user }
      let!(:occupancy) do
        create(
          :occupancy,
          :active,
          entry_event: event,
          user: user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: account,
        )
      end

      it "orphans the occupancy" do
        expect { action.perform }.to change { occupancy.reload.orphan? }.from(false).to(true)
      end

      it "sends the occupancy through the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).to receive(:process).with(occupancy)
        action.perform
      end

      it "sets the order_detail problem status" do
        action.perform
        expect(order_detail.reload).to be_problem
      end

      it "does not assign pricing" do
        action.perform
        expect(order_detail.reload.price_policy).to be_nil
      end

      it "sets the order detail fulfilled at time" do
        action.perform
        expect(order_detail.reload.fulfilled_at).to eq occupancy.reload.orphaned_at
      end

      it "triggers an email" do
        expect { action.perform }.to enqueue_mail(ProblemOrderMailer, :notify_user)
      end
    end

    context "with a long-running non-order occupancy" do
      let(:user) { create(:user, :staff, card_number: "123456", facility: secure_room.facility) }
      let(:event) { create :event, :successful, occurred_at: 3.days.ago, card_reader: card_reader, user: user }
      let!(:occupancy) do
        create(
          :occupancy,
          :active,
          entry_event: event,
          user: user,
          secure_room: secure_room,
        )
      end

      it "orphans the occupancy" do
        expect { action.perform }.to change { occupancy.reload.orphan? }.from(false).to(true)
      end

      it "sends the occupancy through the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).to receive(:process).with(occupancy)
        action.perform
      end

      it "does not generate an order" do
        action.perform
        expect(user.orders).to be_blank
      end

      it "does not trigger an email" do
        expect { action.perform }.not_to enqueue_mail
      end
    end

    context "with a short-term active occupancy" do
      let!(:occupancy) do
        create(
          :occupancy,
          :active,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      it "does not orphan the occupancy" do
        expect { action.perform }.not_to change { occupancy.reload.orphan? }
      end

      it "does not involve the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).not_to receive(:process)
        action.perform
      end
    end

    context "with an already completed occupancy" do
      let!(:occupancy) do
        create(
          :occupancy,
          :complete,
          user: order_detail.user,
          secure_room: secure_room,
          order_detail: order_detail,
          account: order_detail.account,
        )
      end

      it "does not orphan the occupancy" do
        expect { action.perform }.not_to change { occupancy.reload.orphan? }
      end

      it "does not involve the order handler" do
        expect(SecureRooms::AccessHandlers::OrderHandler).not_to receive(:process)
        action.perform
      end
    end
  end
end
