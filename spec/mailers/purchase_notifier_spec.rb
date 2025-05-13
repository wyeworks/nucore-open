# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurchaseNotifier do
  let(:email) { ActionMailer::Base.deliveries.last }
  let(:facility) { create(:setup_facility) }
  let(:order) { create(:purchased_order, product:) }
  let(:product) { create(:setup_instrument, facility:) }
  let(:user) { order.user }
  let(:other_user) { create(:user) }

  describe ".order_notification" do
    let(:deliver_mail) { described_class.order_notification(order, recipient).deliver_now }
    let(:recipient) { "orders@example.net" }

    context "when created by order user" do
      before { deliver_mail }

      it "generates an order notification", :aggregate_failures do
        expect(email.to).to eq [recipient]
        expect(email.subject).to eq("#{facility.name} Order Received for #{product.name}")
        expect(email.html_part.to_s).to match(/Ordered By.+#{user.full_name}/m)
        expect(email.reply_to).to eq [order.created_by_user.email]
        expect(email.text_part.to_s).to include("Ordered By: #{user.full_name}")
        expect(email.html_part.to_s).to match(/Payment Source.+#{order.account}/m)
        expect(email.text_part.to_s).to include("Payment Source: #{order.account}")
        expect(email.html_part.to_s).not_to include("Thank you for your order")
        expect(email.text_part.to_s).not_to include("Thank you for your order")
        expect(email.html_part.to_s).to_not include("Order For")
        expect(email.text_part.to_s).to_not include("Order For")
      end
    end

    context "when created on behalf of user" do
      before do
        order.update_attribute(:created_by_user, other_user)
        deliver_mail
      end

      it "does include order for" do
        expect(email.html_part.to_s).to include("Order For")
        expect(email.text_part.to_s).to include("Order For")
      end
    end

    context "when there're multiple products" do
      let(:product2) { create(:setup_item, facility:) }

      before do
        order_details = order.add(product2)
        order_details.each do |od|
          od.ordered_at ||= Time.zone.now
          od.order_status ||= OrderStatus.new_status
        end
        order.save!

        deliver_mail
      end

      it "sets the subject correctly" do
        expect(email.subject).to eq("#{facility.name} Order Received for Multiple Items")
      end
    end
  end

  describe ".product_order_notification" do
    let(:order_detail) { order.order_details.first }
    let(:recipient) { "orders@example.net" }

    let(:deliver_mail) do
      described_class.product_order_notification(order_detail, recipient).deliver_now
    end

    context "when created by order user" do
      before { deliver_mail }

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
        expect(email.html_part.to_s).to_not include("Order For")
        expect(email.text_part.to_s).to_not include("Order For")
      end
    end

    context "when created on behalf of user" do
      before do
        order.update_attribute(:created_by_user, other_user)
        deliver_mail
      end

      it "does include order for" do
        expect(email.html_part.to_s).to include("Order For")
        expect(email.text_part.to_s).to include("Order For")
      end
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
      expect(email.html_part.to_s).to_not include("Order For")
      expect(email.text_part.to_s).to_not include("Order For")
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

      it "does include order for" do
        expect(email.html_part.to_s).to include("Order For")
        expect(email.text_part.to_s).to include("Order For")
      end

      context "with a note" do
        let(:note) { "*NOTE CONTENT*" }
        it { expect(email.text_part.to_s).to include("*NOTE CONTENT*") }
        it { expect(email.html_part.to_s).to include("*NOTE CONTENT*") }
      end
    end
  end
end
