# frozen_string_literal: true

require "rails_helper"

RSpec.describe Account do
  let(:account_users_attributes) { [{ user: user, created_by: user.id, user_role: "Owner" }] }
  let(:cc_account) { create(:credit_card_account, account_users_attributes: account_users_attributes) }
  let(:facility) { create(:setup_facility) }
  let(:item) { create(:setup_item, facility: facility) }
  let(:po_account) { create(:purchase_order_account, account_users_attributes: account_users_attributes) }
  let(:user) { create(:user) }

  before :each do
    facility.update(accepts_cc: true, accepts_po: true)
    item.reload
  end

  context "product facility does not accept purchase orders" do
    before :each do
      po_account.price_group_members = item.price_groups.map do |price_group|
        AccountPriceGroupMember.create!(account_id: po_account.id, price_group_id: price_group.id)
      end
      expect(po_account.validate_against_product(item, user)).to be_nil
      facility.update(accepts_po: false)
      item.reload
    end

    it "should produce an error string" do
      expect(po_account.validate_against_product(item, user))
        .to match /\bdoes not accept\b/
    end
  end

  context "product facility does not accept credit cards" do
    before :each do
      cc_account.price_group_members = item.price_groups.map do |price_group|
        AccountPriceGroupMember.create!(account_id: cc_account.id, price_group_id: price_group.id)
      end
      expect(cc_account.validate_against_product(item, user)).to be_nil
      facility.update(accepts_cc: false)
      item.reload
    end

    it "should produce an error string" do
      expect(cc_account.validate_against_product(item, user))
        .to match /\bdoes not accept\b/
    end
  end
end
