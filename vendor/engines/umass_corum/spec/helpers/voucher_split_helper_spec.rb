# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::VoucherSplitHelper do
  let(:account) { create(:voucher_split_account) }
  let(:user) { create(:user, :purchaser, account: account, administrator: account.owner_user) }
  let(:order) { create(:order, user: user, created_by: user.id) }
  let(:item) { create(:setup_item) }
  let(:order_detail) { create(:order_detail, :completed, account: account, product: item, order: order, actual_cost: 500, actual_subsidy: 0) }

  describe "#mivp_total" do
    it "returns the correct amount" do
      expect(mivp_total(order_detail)).to eq("$250.00")
    end
  end

  describe "#primary_total" do
    it "returns the correct amount" do
      expect(primary_total(order_detail)).to eq("$250.00")
    end
  end
end
