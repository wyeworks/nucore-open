# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseNotifier do
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { create(:setup_facility) }
  let(:order) { create(:purchased_order, product:) }
  let(:product) { create(:setup_instrument, facility:) }
  let(:user) { order.user }

  describe ".order_notification" do
    before { described_class.order_notification(order, recipient).deliver_now }

    let(:recipient) { "orders@example.net" }

    it "generates an order notification", :aggregate_failures do
      expect(email.to).to eq [recipient]
      expect(email.subject).to include("Order Notification")
      expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
      expect(email.reply_to).to eq [order.created_by_user.email]
      expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
      expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
      expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
      expect(email.html_part.to_s).not_to include("Thank you for your order")
      expect(email.text_part.to_s).not_to include("Thank you for your order")
    end
  end

  describe ".product_order_notification" do
    before { described_class.product_order_notification(order_detail, recipient).deliver_now }

    let(:order_detail) { order.order_details.first }
    let(:recipient) { "orders@example.net" }

    it "generates a product order notification", :aggregate_failures do
      expect(email.to).to eq [recipient]
      expect(email.subject).to include("#{product} Order Notification")
      expect(email.html_part.to_s).to include(order_detail.to_s)
      expect(email.text_part.to_s).to include(order_detail.to_s)
      expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
      expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
      expect(email.reply_to).to eq [order.created_by_user.email]
      expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
      expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
      expect(email.html_part.to_s).not_to include("Thank you for your order")
      expect(email.text_part.to_s).not_to include("Thank you for your order")
    end
  end

  describe ".order_receipt" do
    let(:note) { nil }

    before(:each) do
      order.order_details.first.update_attribute(:note, note) if note.present?
      described_class.order_receipt(order:, user:).deliver_now
    end

    it "generates a receipt", :aggregate_failures do
      expect(email.to).to eq [user.email]
      expect(email.subject).to include("Order Receipt")
      expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
      expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
      expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
      expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
      expect(email.html_part.to_s).to include("Thank you for your order")
      expect(email.text_part.to_s).to include("Thank you for your order")
    end

    context "when ordered on behalf of another user" do
      let(:administrator) { create(:user, :administrator) }
      let(:order) { create(:purchased_order, product:, created_by: administrator.id) }

      it "mentions who placed the order in the receipt", :aggregate_failures do
        expect(email.html_part.to_s)
          .to match(/Ordered By.+#{administrator.full_name}/m)
        expect(email.text_part.to_s)
          .to include("Ordered By: #{administrator.full_name}")
      end

      context "with a note" do
        let(:note) { "*NOTE CONTENT*" }
        it { expect(email.text_part.to_s).to include("*NOTE CONTENT*") }
        it { expect(email.html_part.to_s).to include("*NOTE CONTENT*") }
      end
    end
  end

  context "order for" do
    let(:order_for_field) { "Order For" }
    let(:recipient) { "test@example.com" }

    context "order created by admin" do
      let(:admin) { create(:user, :administrator) }

      before do
        order.update_attribute(:created_by_user, admin)
        described_class.order_notification(order, recipient).deliver_now
      end

      shared_examples "includes involved users info" do |part|
        let(:mail_content) { email.send(part).to_s }

        it "includes created by and order for in #{part}" do
          expect(mail_content).to include(order_for_field)
          expect(mail_content).to include(order.user.full_name)
          expect(mail_content).to include(order.user.email)
          expect(mail_content).to include(order.created_by_user.email)
          expect(mail_content).to include(order.created_by_user.full_name)
        end
      end

      include_examples "includes involved users info", :html_part
      include_examples "includes involved users info", :text_part
    end

    context "order created by user" do
      before do
        order.update_attribute(:user, order.created_by_user)
        described_class.order_notification(order, recipient).deliver_now
      end

      it "does not include order for" do
        expect(email.html_part.to_s).to_not include(order_for_field)
      end

      it "does not include order for" do
        expect(email.text_part.to_s).to_not include(order_for_field)
      end
    end
  end
end
