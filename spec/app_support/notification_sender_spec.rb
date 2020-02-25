# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationSender, :aggregate_failures do
  subject(:notification_sender) { described_class.new(facility, order_detail_ids) }

  let(:accounts) do
    account_owners.map do |user|
      FactoryBot.create_list(:setup_account, 2, owner: user)
    end.flatten
  end
  let(:account_ids) { accounts.map(&:id) }
  let(:delivery) { OpenStruct.new(deliver_now: true) }
  let(:facility) { item.facility }
  let(:item) { FactoryBot.create(:setup_item, :with_facility_account) }
  let!(:order_details) do
    accounts.map do |account|
      FactoryBot.create(:account_user, :purchaser, user_id: purchaser.id, account_id: account.id)
      Array.new(3) { place_product_order(purchaser, facility, item, account) }
    end.flatten
  end
  let(:order_detail_ids) { order_details.map(&:id) }
  let(:price_policy) { item.price_policies.first }
  let(:account_owners) { FactoryBot.create_list(:user, 2) }
  let(:purchaser) { FactoryBot.create(:user) }

  before(:each) do
    # This feature only gets used when there is a review period, so go ahead and enable it.
    allow(SettingsHelper).to receive(:has_review_period?).and_return true

    OrderDetail.update_all(state: "complete", price_policy_id: price_policy.id)
  end

  describe "#perform" do
    context "when multiple users administer multiple accounts" do
      context "and multiple accounts have complete orders" do
        it "notifies each user once while setting order_details to reviewed" do
          account_owners.each do |user|
            expect(Notifier)
              .to receive(:review_orders)
              .with(user: user,
                    accounts: match_array(AccountUser.where(user_id: user.id).map(&:account)),
                    facility: facility)
              .once
              .and_return(delivery)
          end

          expect(notification_sender.perform).to be_truthy
          expect(notification_sender.account_ids_to_notify).to match_array(account_ids)
          expect(order_details.map(&:reload)).to be_all(&:reviewed_at?)
        end

      end

      context "when an order_detail ID is invalid" do
        let(:order_detail_ids) { [-1, order_details.first.id] }

        it "errors while not setting the valid ID as reviewed" do
          expect(notification_sender.perform).to be_falsey
          expect(notification_sender.errors.first).to include("-1")
          expect(order_details.first.reload).not_to be_reviewed
        end
      end
    end
  end
end
