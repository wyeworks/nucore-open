# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderAssignmentMailer do
  let(:assigned_user) { FactoryBot.build(:user) }
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { FactoryBot.build_stubbed(:facility) }

  def stubbed_order_detail(order)
    FactoryBot.build_stubbed(:order_detail,
                             assigned_user:,
                             order:)
  end

  describe ".notify_assigned_user" do
    context "when given a single order_detail" do
      let(:order) { FactoryBot.build_stubbed(:order, facility:) }
      let(:order_detail) { stubbed_order_detail(order) }

      before { described_class.notify_assigned_user(order_detail).deliver_now }

      it "generates an order assignment notification", :aggregate_failures do
        expect(email.to).to eq [assigned_user.email]
        expect(email.subject).to include("Order Assignment Notice")
        expect(email.html_part.to_s)
          .to include(order_detail.to_s)
          .and include("assigned this")
        expect(email.text_part.to_s)
          .to include(order_detail.to_s)
          .and include("assigned this")
      end
    end

    context "when given multiple order_details" do
      let(:orders) { FactoryBot.build_stubbed_list(:order, 3, facility:) }
      let(:order_details) do
        orders.map { |order| stubbed_order_detail(order) }
      end

      before { described_class.notify_assigned_user(order_details).deliver_now }

      it "generates an order assignment notification", :aggregate_failures do
        expect(email.to).to eq [assigned_user.email]
        expect(email.subject).to include("Order Assignment Notice")
        expect(email.html_part.to_s).to include("assigned these")
        expect(email.text_part.to_s).to include("assigned these")
        order_details.each do |order_detail|
          expect(email.html_part.to_s).to include(order_detail.to_s)
          expect(email.text_part.to_s).to include(order_detail.to_s)
        end
      end
    end
  end
end
