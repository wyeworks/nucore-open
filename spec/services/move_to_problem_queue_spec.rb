# frozen_string_literal: true

require "rails_helper"

RSpec.describe MoveToProblemQueue do
  let(:mailer) { double("mail object") }
  let(:message) { double(deliver_later: nil) }
  let(:order) { FactoryBot.build(:order, :purchased) }
  let(:reservation) { FactoryBot.build(:reservation) }
  let(:order_detail) { FactoryBot.build(:order_detail, order: order, reservation: reservation, product: product) }
  before do
    expect(order_detail).to receive_messages(
      complete!: true,
      problem?: true,
    )
    allow(ProblemOrderMailer).to receive(:with).and_return(mailer)
    allow(mailer).to receive(:notify_user).and_return(message)
    allow(mailer).to receive(:notify_user_with_resolution_option).and_return(message)
  end

  describe "with the resolvable flag turned on for the product" do
    let(:product) { FactoryBot.build(:instrument, problems_resolvable_by_user: true) }

    describe "an order failing because of missing price policy" do
      before { expect(order_detail).to receive(:requires_but_missing_actuals?).and_return(false) }

      it "triggers the regular resolution email" do
        expect(ProblemOrderMailer).to receive(:with).with(order_detail)
        expect(mailer).to receive(:notify_user)
        described_class.move!(order_detail, cause: :cause)
      end
    end

    describe "an order failing because it is missing actuals" do
      before { expect(order_detail).to receive(:requires_but_missing_actuals?).and_return(true) }

      describe "when it has a start at" do
        before { reservation.actual_start_at = 1.day.ago }

        it "triggers the notify with resolution email" do
          expect(ProblemOrderMailer).to receive(:with).with(order_detail)
          expect(mailer).to receive(:notify_user_with_resolution_option)

          described_class.move!(order_detail, cause: :cause)
        end
      end

      describe "when it is missing start at" do
        before { reservation.actual_start_at = nil }
        it "triggers the notify with resolution email" do
          expect(ProblemOrderMailer).to receive(:with).with(order_detail)
          expect(mailer).to receive(:notify_user)

          described_class.move!(order_detail, cause: :cause)
        end
      end

    end
  end

  describe "with the resolvable flag turned off for the product" do
    let(:product) { FactoryBot.build(:instrument, problems_resolvable_by_user: false) }
    before { expect(order_detail).to receive(:requires_but_missing_actuals?).and_return(true) }

    it "triggers the regular resolution email" do
      expect(ProblemOrderMailer).to receive(:with).with(order_detail)
      expect(mailer).to receive(:notify_user)

      described_class.move!(order_detail, cause: :cause_example)
    end
  end
end
