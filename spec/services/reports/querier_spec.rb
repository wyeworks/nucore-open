# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::Querier do
  let(:user) { FactoryBot.create(:user) }
  let(:item) { FactoryBot.create(:setup_item) }
  let(:facility) { item.facility }
  let(:account) { FactoryBot.create(:setup_account, :with_account_owner, owner: user) }
  let!(:order_detail) { place_product_order(user, facility, item, account) }

  let(:options) do
    {
      order_status_id: OrderStatus.new_status.id,
      current_facility: facility,
      date_range_field: :ordered_at,
      date_range_start: 1.day.ago,
      date_range_end: 1.day.from_now,
    }
  end
  let(:querier) { described_class.new(options) }

  it "includes the order detail" do
    expect(querier.perform).to include(order_detail)
  end

  describe "with a merge order" do
    let(:order) { order_detail.order }
    let(:merge_order) { FactoryBot.create(:merge_order, merge_with_order: order) }
    let!(:merge_order_detail) do
      FactoryBot.create(:order_detail, product: item,
                                       order_status: OrderStatus.new_status, order: merge_order)
    end

    it "excludes the merge order detail" do
      expect(querier.perform).not_to include(merge_order_detail)
    end
  end
end
