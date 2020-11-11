# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::OrderDetail do
  subject { Api::OrderDetail.new(order_detail) }

  let(:order) { double(Order, user: ordered_for) }
  let(:order_detail) { double(OrderDetail, account: account, order: order, order_number: "12-3") }
  let(:ordered_for) { build(:user, id: 2) }

  describe "#to_h" do
    context "when the order_detail has an account" do
      let(:account) { double(Account, id: 1, owner_user: account_owner) }
      let(:account_owner) { build(:user, id: 1) }
      let(:account_user) { double(AccountUser, user: account_owner) }

      it "generates the expected hash" do
        expect(subject.to_h).to match a_hash_including(
          order_number: "12-3",
          ordered_for: {
            id: ordered_for.id,
            name: ordered_for.name,
            username: ordered_for.username,
            email: ordered_for.email,
          },
          account: {
            id: account.id,
            owner: {
              id: account_owner.id,
              name: account_owner.name,
              username: account_owner.username,
              email: account_owner.email,
            },
          },
        )
      end
    end

    context "when the order_detail has no account" do
      let(:account) { nil }

      it "generates the expected hash" do
        expect(subject.to_h).to match a_hash_including(
          order_number: "12-3",
          ordered_for: an_instance_of(Hash),
          account: nil,
        )
      end
    end
  end
end
