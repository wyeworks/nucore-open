# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetails::DisputeResolvedNotifier do
  let(:item) { create(:setup_item) }
  let(:order) { create(:complete_order, product: item) }
  let(:order_detail) { create(:order_detail, :disputed, order: order, product: item, account: order.account) }
  let(:user) { create(:user) }
  subject(:notifier) { described_class.new(order_detail) }

  def resolve_dispute_and_notify
    order_detail.update!(dispute_resolved_at: Time.current, dispute_resolved_reason: "resolved")
    notifier.notify
  end

  it "does not notify on a clean object" do
    expect { notifier.notify }.not_to change(ActionMailer::Base, :deliveries)
  end

  it "triggers an email and log the order detail if the resolved at moves from blank to present" do
    expect { resolve_dispute_and_notify }.to change(ActionMailer::Base, :deliveries)
    log_event = LogEvent.find_by(loggable: order_detail, event_type: :resolve)
     expect(log_event).to be_present
  end

  it "does not trigger an email if the resolve changes" do
    order_detail.update!(dispute_resolved_at: Time.current, dispute_resolved_reason: "resolved")
    order_detail.clear_changes_information

    expect { resolve_dispute_and_notify }.not_to change(ActionMailer::Base, :deliveries)
  end

  context "with a business business_administrator" do
    let!(:business_administrator) { create(:user, :business_administrator, email: "ba@example.com", account: order_detail.account) }

    it "triggers an email to the dispute_by and the account administrators" do
      expect { resolve_dispute_and_notify }.to change { ActionMailer::Base.deliveries.map(&:to) }
        .by(containing_exactly(
              [order_detail.dispute_by.email],
              [order_detail.account.owner_user.email],
              [business_administrator.email],
            ))
    end
  end

end
