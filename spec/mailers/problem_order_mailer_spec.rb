# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProblemOrderMailer do
  let(:facility) { create(:setup_facility, email: "facility@example.com") }
  let(:instrument) do
    create(:setup_instrument, :timer, :always_available, charge_for: :usage, facility:, problems_resolvable_by_user: true)
  end
  let!(:reservation) do
    create(
      :purchased_reservation,
      product: instrument,
      reserve_start_at: 2.hours.ago,
      reserve_end_at: 1.hour.ago,
      actual_start_at: 1.hour.ago,
      actual_end_at: nil,
    )
  end
  let(:order_detail) { reservation.order_detail.reload }
  let(:user) { order_detail.user }

  before { MoveToProblemQueue.move!(reservation.order_detail, cause: :reservation_started) }

  shared_examples_for "a problem order email" do
    it "addresses the order's user" do
      expect(mail.to).to eq([user.email])
    end

    it "uses the problem order subject" do
      expect(mail.subject).to end_with("Your order requires additional information")
    end

    it "replies to the facility" do
      expect(mail.reply_to).to eq([facility.email])
    end

    context "when the facility has no email" do
      before { facility.update!(email: nil) }

      it "falls back to the application from address" do
        expect(mail.reply_to).to eq([Settings.email.from])
      end
    end

    it "offers a way to contact the facility", :aggregate_failures do
      expect(mail.html_part.to_s).to include("mailto:#{facility.email}")
      expect(mail.text_part.to_s).to include("mailto:#{facility.email}")
    end

    it "names the product and the facility", :aggregate_failures do
      expect(mail.html_part.to_s).to include(instrument.name, facility.name)
      expect(mail.text_part.to_s).to include(instrument.name, facility.name)
    end
  end

  describe ".notify_user" do
    let(:mail) { described_class.notify_user(order_detail) }

    it_behaves_like "a problem order email"

    it "links to the order detail", :aggregate_failures do
      order_detail_path = order_order_detail_path(order_detail.order, order_detail)

      expect(mail.html_part.to_s).to include(order_detail_path)
      expect(mail.text_part.to_s).to include(order_detail_path)
    end
  end

  describe ".notify_user_with_resolution_option" do
    let(:mail) { described_class.notify_user_with_resolution_option(order_detail) }

    it_behaves_like "a problem order email"

    it "links to the problem reservation resolution page", :aggregate_failures do
      resolution_path = edit_problem_reservation_path(reservation)

      expect(mail.html_part.to_s).to include(resolution_path)
      expect(mail.text_part.to_s).to include(resolution_path)
    end
  end
end
