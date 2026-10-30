# frozen_string_literal: true

require "rails_helper"

RSpec.describe MostRecentlyUsedSearcher do
  describe "#recently_used_facilities" do
    let(:account) { create(:setup_account, owner: user) }
    let(:facilities) { products.map(&:facility) }
    let(:limit) { 5 }
    let(:products) { create_list(:setup_item, 6) }
    let(:user) { create(:user) }
    let(:recently_used_facilities) { MostRecentlyUsedSearcher.new(user).recently_used_facilities(limit) }

    context "when the user has no orders" do
      it { expect(recently_used_facilities).to be_empty }
    end

    context "when the user has orders" do
      let!(:old_order) { create(:setup_order, :purchased, account:, product: products.first, user:, ordered_at: 1.week.ago) }
      let!(:new_order) { create(:setup_order, :purchased, account:, product: products.second, user:, ordered_at: 1.day.ago) }
      let!(:unpurchased_order) { create(:setup_order, account:, product: products.third, user:) }

      it "returns facilities that the user has ordered from" do
        expect(recently_used_facilities).to contain_exactly(new_order.facility, old_order.facility)
      end

      context "when there are orders in more facilities than the limit" do
        before(:each) do
          products.each_with_index do |product, i|
            create(:setup_order, :purchased, account:, product:, user:, ordered_at: i.days.ago)
          end
        end

        it "returns only 5 facilities" do
          expect(recently_used_facilities.length).to eq 5
        end
      end
    end
  end

  describe "#recently_used_products" do
    let(:account) { create(:setup_account, owner: user) }
    let(:facilities) { products.map(&:facility) }
    let(:limit) { 5 }
    let(:products) { create_list(:setup_item, 6) }
    let(:user) { create(:user) }
    let(:recently_used_products) { MostRecentlyUsedSearcher.new(user).recently_used_products(limit) }

    context "when the user has no orders" do
      it { expect(recently_used_products).to be_empty }
    end

    context "when the user has orders" do
      let!(:old_order) { create(:setup_order, :purchased, account:, product: products.first, user:, ordered_at: 1.week.ago) }
      let!(:new_order) { create(:setup_order, :purchased, account:, product: products.second, user:, ordered_at: 1.day.ago) }
      let!(:unpurchased_order) { create(:setup_order, account:, product: products.third, user:) }

      it "returns products that the user has ordered" do
        expect(recently_used_products).to contain_exactly(new_order.order_details.first.product, old_order.order_details.first.product)
      end

      context "when there are more recently used products than the limit" do
        before(:each) do
          products.each_with_index do |product, i|
            create(:setup_order, :purchased, account:, product:, user:, ordered_at: i.days.ago)
          end
        end

        it "returns only 5 products" do
          expect(recently_used_products.length).to eq 5
        end
      end
    end
  end
end
