# frozen_string_literal: true

RSpec.shared_examples_for "NonReservationProduct" do |product_type|
  let(:account) { create(:setup_account, owner: user) }
  let!(:user) { FactoryBot.create(:user) }
  let(:product_type) { product_type }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:product) do
    FactoryBot.create(product_type,
                      facility: facility)
  end
  let(:order) { create(:order, account: account, created_by_user: user, user: user) }
  let(:order_detail) { order.order_details.create(attributes_for(:order_detail, account: account, product: product, quantity: 1)) }

  let(:price_group) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group2) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group3) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group4) { FactoryBot.create(:price_group, facility: facility) }

  let!(:pp_g1) { make_price_policy(unit_cost: 22, price_group: price_group) }
  let!(:pp_g2) { make_price_policy(unit_cost: 23, price_group: price_group2) }
  let!(:pp_g3) { make_price_policy(unit_cost: 5, price_group: price_group3) }
  let!(:pp_g4) { make_price_policy(unit_cost: 4, price_group: price_group4) }

  let!(:account_price_group_member) { FactoryBot.create(:account_price_group_member, account: order.account, price_group: price_group) }
  let!(:account_price_group_member2) { FactoryBot.create(:account_price_group_member, account: order.account, price_group: price_group2) }

  context "#cheapest_price_policy" do
    context "current policies" do
      it "should find the cheapest price policy" do
        expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
      end

      context "with user-based price groups enabled", feature_setting: { user_based_price_groups: true } do
        it "should find the cheapest price policy including groups that belong to the user" do
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group3)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group4)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g4)
        end
      end

      context "without user-based price groups enabled", feature_setting: { user_based_price_groups: false } do
        it "should ignore cheaper price policies that belong to the user but not the account" do
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group3)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group4)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end

      it "should use the base rate when that is the cheapest and others have equal unit_cost" do
        base_pg = PriceGroup.base
        base_pp = make_price_policy(unit_cost: 1, price_group: base_pg)

        [base_pg, price_group3, price_group4].each do |pg|
          create(:account_price_group_member, account: account, price_group: pg)
        end

        [pp_g1, pp_g2, pp_g3, pp_g4].each do |pp|
          pp.update_attribute :unit_cost, base_pp.unit_cost

          expect(product.cheapest_price_policy(order_detail)).to eq(base_pp)
        end
      end

      context "with an expired price policy" do
        it "should ignore the expired price policy, even if it is cheaper" do
          make_price_policy(unit_cost: 1, price_group: price_group, start_date: 7.days.ago, expire_date: 1.day.ago)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end
      context "with a restricted price_policy" do
        it "should ignore the restricted price policy even if it is cheaper" do
          price_group5 = FactoryBot.create(:price_group, facility: facility)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group5)
          make_price_policy(unit_cost: 1, price_group: price_group5, can_purchase: false)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end
    end

    context "past policies" do
      let!(:pp_past_group1) { make_price_policy(unit_cost: 7, price_group: price_group2, start_date: 3.days.ago, expire_date: 1.day.ago) }
      let!(:pp_past_group2) { make_price_policy(unit_cost: 8, price_group: price_group, start_date: 3.days.ago, expire_date: 1.day.ago) }

      it "should find the cheapest policy of two past policies" do
        expect(product.cheapest_price_policy(order_detail, 2.days.ago)).to eq(pp_past_group1)
      end
      it "should ignore the current price policies" do
        pp_current_group1 = make_price_policy(unit_cost: 2, price_group: price_group, start_date: 1.day.ago, expire_date: 1.day.from_now)
        pp_current_group2 = make_price_policy(unit_cost: 5, price_group: price_group2, start_date: 1.day.ago, expire_date: 1.day.from_now)

        expect(product.cheapest_price_policy(order_detail, 2.days.ago)).to eq(pp_past_group1)
      end
      it "should still find the cheapest current if no date" do
        pp_current_group1 = make_price_policy(unit_cost: 2, price_group: price_group, start_date: 1.day.ago, expire_date: 1.day.from_now)
        pp_current_group2 = make_price_policy(unit_cost: 5, price_group: price_group2, start_date: 1.day.ago, expire_date: 1.day.from_now)

        expect(product.cheapest_price_policy(order_detail, Time.zone.now)).to eq(pp_current_group1)
      end
    end
  end

  private

  def make_price_policy(attr = {})
    product.send(:"#{product_type}_price_policies").create!(FactoryBot.attributes_for(:"#{product_type}_price_policy", attr))
  end
end

RSpec.shared_examples_for "ReservationProduct" do |product_type|
  let(:account) { create(:setup_account, owner: user) }
  let!(:user) { FactoryBot.create(:user) }
  let(:product_type) { product_type }
  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:product) do
    FactoryBot.create(product_type,
                      facility: facility)
  end
  let(:order) { create(:order, account: account, created_by_user: user, user: user) }
  let(:order_detail) { order.order_details.create(attributes_for(:order_detail, account: account, product: product)) }

  let(:price_group) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group2) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group3) { FactoryBot.create(:price_group, facility: facility) }
  let(:price_group4) { FactoryBot.create(:price_group, facility: facility) }

  let!(:pp_g1) { make_price_policy(usage_rate: 22, price_group: price_group) }
  let!(:pp_g2) { make_price_policy(usage_rate: 23, price_group: price_group2) }
  let!(:pp_g3) { make_price_policy(usage_rate: 5, price_group: price_group3) }
  let!(:pp_g4) { make_price_policy(usage_rate: 4, price_group: price_group4) }

  let!(:schedule_rule) { product.schedule_rules << FactoryBot.build(:schedule_rule) }

  let!(:account_price_group_member) { FactoryBot.create(:account_price_group_member, account: account, price_group: price_group) }
  let!(:account_price_group_member2) { FactoryBot.create(:account_price_group_member, account: account, price_group: price_group2) }

  let!(:reservation) do
    FactoryBot.create(:reservation,
                      product: product,
                      reserve_start_at: 1.hour.from_now,
                      order_detail: order_detail)
  end

  context "#cheapest_price_policy" do
    context "current policies" do
      it "should find the cheapest price policy" do
        expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
      end
      context "with user-based price groups enabled", feature_setting: { user_based_price_groups: true } do
        it "should find the cheapest price policy including groups that belong to the user" do
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group3)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group4)
          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g4)
        end
      end

      context "without user-based price groups enabled", feature_setting: { user_based_price_groups: false } do
        it "should ignore cheaper price policies that belong to the user but not the account" do
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group3)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group4)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end

      context "with an expired price policy" do
        it "should ignore the expired price policy, even if it is cheaper" do
          make_price_policy(usage_rate: 1, price_group: price_group, start_date: 7.days.ago, expire_date: 1.day.ago)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end
      context "with a restricted price_policy" do
        it "should ignore the restricted price policy even if it is cheaper" do
          price_group5 = FactoryBot.create(:price_group, facility: facility)
          FactoryBot.create(:user_price_group_member, user: user, price_group: price_group5)
          make_price_policy(usage_rate: 1, price_group: price_group5, can_purchase: false)

          expect(product.cheapest_price_policy(order_detail)).to eq(pp_g1)
        end
      end
    end
    context "past policies" do
      let!(:pp_past_group1) { make_price_policy(usage_rate: 7, price_group: price_group2, start_date: 3.days.ago, expire_date: 1.day.ago) }
      let!(:pp_past_group2) { make_price_policy(usage_rate: 8, price_group: price_group, start_date: 3.days.ago, expire_date: 1.day.ago) }

      it "should find the cheapest policy of two past policies" do
        expect(product.cheapest_price_policy(order_detail, 2.days.ago)).to eq(pp_past_group1)
      end
      it "should ignore the current price policies" do
        pp_current_group1 = make_price_policy(usage_rate: 2, price_group: price_group, start_date: 1.day.ago, expire_date: 1.day.from_now)
        pp_current_group2 = make_price_policy(usage_rate: 5, price_group: price_group2, start_date: 1.day.ago, expire_date: 1.day.from_now)

        expect(product.cheapest_price_policy(order_detail, 2.days.ago)).to eq(pp_past_group1)
      end
      it "should still find the cheapest current if no date" do
        pp_current_group1 = make_price_policy(usage_rate: 2, price_group: price_group, start_date: 1.day.ago, expire_date: 1.day.from_now)
        pp_current_group2 = make_price_policy(usage_rate: 5, price_group: price_group2, start_date: 1.day.ago, expire_date: 1.day.from_now)

        expect(product.cheapest_price_policy(order_detail, Time.zone.now)).to eq(pp_current_group1)
      end
    end
  end

  private

  def make_price_policy(attr = {})
    create :"#{product_type}_price_policy", attr.merge(product: product)
  end
end
