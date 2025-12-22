# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderDetail::Calculations do
  describe "#grand_total" do
    let(:account) { create(:setup_account) }
    let(:product) { create(:setup_item) }
    let(:expected_grand_total) do
      OrderDetail.sum do |order_detail|
        order_detail.actual_total || order_detail.estimated_total
      end
    end
    let(:price_group) { product.price_groups.first }
    let(:user) { create(:user) }

    before do
      create(:account_user, :purchaser, user:, account:)
      create(
        :account_price_group_member,
        account:,
        price_group:,
      )
      create_list(:setup_order, 2, product:, account:, user:)
      create_list(:purchased_order, 2, product:, account:, user:).each do |order|
        order.order_details.map(&:assign_actual_price)
        order.order_details.map(&:save)
      end
    end

    it "is greater than zero" do
      expect(OrderDetail.grand_total).to be > 0
    end

    it "sums actual_total || estimated_total" do
      expect(OrderDetail.grand_total).to be_within(0.001).of(expected_grand_total)
    end
  end
end
