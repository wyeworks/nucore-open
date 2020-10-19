# frozen_string_literal: true

require "rails_helper"

RSpec.describe BulkEmail::RecipientSearcher do
  shared_examples_for "active/inactive users" do
    describe "with an active user" do
      it "returns the user" do
        expect(users).to include(user)
      end
    end

    describe "with an inactive user" do
      before { user.update(suspended_at: Time.current) }

      it "does not include the user" do
        expect(users).not_to include(user)
      end
    end
  end

  subject(:searcher) { described_class.new(facility, params) }

  let(:users) { searcher.do_search }
  let(:owner) { FactoryBot.create(:user) }
  let(:purchaser)  { FactoryBot.create(:user) }
  let(:purchaser2) { FactoryBot.create(:user) }
  let(:purchaser3) { FactoryBot.create(:user) }

  let(:facility) { FactoryBot.create(:setup_facility) }

  let(:product) { create_item }
  let(:product2) { create_item }
  let(:product3) { FactoryBot.create(:setup_item, facility: facility, is_archived: true) }

  let(:account) { FactoryBot.create(:setup_account, owner: owner) }
  let(:price_group) { FactoryBot.create(:price_group, facility: facility) }
  let(:usa_today) { Time.current.strftime("%m/%d/%Y") }

  let(:params) do
    {
      bulk_email: { user_types: [:customers] },
      commit: "Submit",
    }
  end

  before { ignore_order_detail_account_validations }

  def create_item
    FactoryBot.create(:setup_item, facility: facility)
  end

  def place_order(purchaser:, product:, account:)
    FactoryBot.create(:setup_order,
                      :purchased,
                      created_by: purchaser.id,
                      product: product,
                      user: purchaser,
                      account: account,
                      ordered_at: Time.current)
  end

  context "#has_search_fields?" do
    context "when providing no search parameters" do
      let(:params) { {} }
      it { is_expected.not_to have_search_fields }
    end

    context "when providing a 'commit' parameter" do
      it { is_expected.to have_search_fields }
    end
  end

  describe "#search_params_as_hidden_fields" do
    let(:params) do
      {
        bulk_email: { user_types: [:customers, :account_users] },
        commit: "Submit",
        facility_id: facility.id,
        start_date: "1/1/2009",
        end_date: "12/31/2016",
        products: [1, 3, 5],
      }
    end
    let(:fragment) { Nokogiri::HTML(searcher.search_params_as_hidden_fields.join("")) }
    let(:end_date_tag) { fragment.css("input[name=end_date]") }
    let(:product_tag_values) { product_tags.map { |product_tag| product_tag.attr("value") } }
    let(:product_tags) { fragment.css("input[name='products[]']") }
    let(:start_date_tag) { fragment.css("input[name=start_date]") }
    let(:user_type_tag_values) { user_type_tags.map { |user_type_tag| user_type_tag.attr("value") } }
    let(:user_type_tags) { fragment.css("input[name='bulk_email[user_types][]']") }

    it "generates an HTML fragment with hidden recipient search parameters" do
      expect(start_date_tag.attr("value").value).to eq("1/1/2009")
      expect(end_date_tag.attr("value").value).to eq("12/31/2016")
      expect(product_tag_values).to match_array %w(1 3 5)
      expect(user_type_tag_values).to match_array %w(customers account_users)
    end
  end

  context "when searching for customers" do
    context "filtered by ordered dates" do
      let!(:od_yesterday) do
        travel_and_return(-1.days) do
          place_order(purchaser: purchaser, product: product, account: account)
        end
      end

      let!(:od_tomorrow) do
        travel_and_return(1.day) do
          place_order(purchaser: purchaser2, product: product2, account: account)
        end
      end

      let!(:od_today) do
        place_order(purchaser: purchaser3, product: product, account: account)
      end

      before(:each) do
        params[:start_date] = start_date
        params[:end_date] = end_date
      end
      let(:start_date) { nil }
      let(:end_date) { nil }

      it_behaves_like "active/inactive users" do
        let(:user) { purchaser }
      end

      context "when the search start_date is today" do
        let(:start_date) { usa_today }

        context "and the end_date is unspecified" do
          it "returns users who ordered today and after" do
            expect(users).to contain_exactly(purchaser3, purchaser2)
          end
        end

        context "and the end_date is today" do
          let(:end_date) { usa_today }

          it "returns users who ordered today only" do
            expect(users).to eq [purchaser3]
          end
        end
      end

      context "when the search start_date is unspecified" do
        context "and the end_date is today" do
          let(:end_date) { usa_today }

          it "returns users who ordered today and before" do
            expect(users).to contain_exactly(purchaser3, purchaser)
          end
        end
      end
    end

    context "when filtering by reservation dates" do
      let(:instrument) do
        FactoryBot.create(:instrument,
                          facility: facility,
                          min_reserve_mins: 60,
                          max_reserve_mins: 60)
      end

      def place_reservation(purchaser, at)
        place_reservation_for_instrument(purchaser, instrument, account, at)
          .order_detail
      end

      let!(:od_yesterday) { place_reservation(purchaser, 1.day.ago) }
      let!(:od_tomorrow) { place_reservation(purchaser2, 1.day.from_now) }
      let!(:od_today) { place_reservation(purchaser3, Time.current) }

      let(:start_date) { nil }
      let(:end_date) { nil }

      before(:each) do
        params[:start_date] = start_date
        params[:end_date] = end_date
      end

      it_behaves_like "active/inactive users" do
        let(:user) { purchaser }
      end

      context "when the search start_date is today" do
        let(:start_date) { usa_today }

        context "and the end_date is unspecified" do
          it "returns users who made reservations today and after" do
            expect(users).to contain_exactly(purchaser3, purchaser2)
          end
        end

        context "and the end_date is today" do
          let(:end_date) { usa_today }

          it "returns users who made reservations today only" do
            expect(users).to eq [purchaser3]
          end
        end
      end

      context "when the search start_date is unspecified" do
        context "and the end_date is today" do
          let(:end_date) { usa_today }

          it "returns users who made reservations today and before" do
            expect(users).to contain_exactly(purchaser3, purchaser)
          end
        end
      end
    end

    context "filtered by products" do
      let!(:order_details) do
        [
          place_order(purchaser: purchaser, product: product, account: account),
          place_order(purchaser: purchaser2, product: product2, account: account),
          place_order(purchaser: purchaser3, product: product3, account: account),
        ]
      end

      it_behaves_like "active/inactive users" do
        let(:user) { purchaser }
      end

      context "when selecting no specific product" do
        it "returns users who are customers of all active products" do
          expect(users).to contain_exactly(purchaser, purchaser2)
        end
      end

      context "when selecting one product" do
        before { params[:products] = [product.id] }

        it "returns only the only user that purchased that product" do
          expect(users).to eq([purchaser])
        end
      end

      context "when selecting two products" do
        before { params[:products] = [product.id, product2.id] }

        it "returns only the users that purchased those two products" do
          expect(users).to contain_exactly(purchaser, purchaser2)
        end
      end
    end

    context "filtered by facilities" do
      let!(:facility2) { FactoryBot.create(:setup_facility) }
      let!(:product_facility2) { FactoryBot.create(:item, facility: facility2) }
      let!(:order_details) do
        [
          place_order(purchaser: purchaser, product: product, account: account),
          place_order(purchaser: purchaser2, product: product_facility2, account: account),
        ]
      end

      describe "when we're searching from within facility 1" do
        before { params[:facilities] = [facility.id, facility2.id] }

        it "does find anything in facility 2" do
          expect(users).to contain_exactly(purchaser)
        end
      end

      describe "when searching in cross-facility" do
        subject(:searcher) { described_class.new(Facility.cross_facility, params) }

        it "finds everything by default" do
          expect(users).to contain_exactly(purchaser, purchaser2)
        end

        describe "when searching for a single facility" do
          before { params[:facilities] = [facility2.id] }

          it "filters to that facility" do
            expect(users).to contain_exactly(purchaser2)
          end
        end
      end
    end
  end

  context "when searching for account_owners" do
    let(:owner2) { FactoryBot.create(:user) }
    let(:owner3) { FactoryBot.create(:user) }
    let!(:order_details) do
      account2 = FactoryBot.create(:setup_account, owner: owner2)
      account3 = FactoryBot.create(:setup_account, owner: owner3)

      [
        place_order(purchaser: purchaser, product: product, account: account),
        place_order(purchaser: purchaser, product: product2, account: account2),
        place_order(purchaser: purchaser, product: product3, account: account3),
      ]
    end

    before { params[:bulk_email].merge!(user_types: [:account_owners]) }

    it_behaves_like "active/inactive users" do
      let(:user) { owner }
    end

    it "finds owners with at least one active product ordered if no other limits" do
      expect(users).to contain_exactly(owner, owner2)
    end

    it "finds owners with limited order details" do
      params[:products] = [product.id, product2.id]
      expect(users).to contain_exactly(owner, owner2)
    end
  end

  context "when searching for customers and account_owners" do
    let(:owner2) { FactoryBot.create(:user) }
    let(:owner3) { FactoryBot.create(:user) }
    let!(:order_details) do
      account2 = FactoryBot.create(:setup_account, owner: owner2)
      account3 = FactoryBot.create(:setup_account, owner: owner3)

      [
        place_order(purchaser: purchaser, product: product, account: account),
        place_order(purchaser: purchaser2, product: product2, account: account2),
        place_order(purchaser: purchaser3, product: product3, account: account3),
      ]
    end

    before { params[:bulk_email].merge!(user_types: [:customers, :account_owners]) }

    it_behaves_like "active/inactive users" do
      let(:user) { owner }
    end

    it "finds owners and purchaser of active products if no other limits" do
      expect(users)
        .to contain_exactly(owner, owner2, purchaser, purchaser2)
    end

    it "finds owners and purchasers with limited order details" do
      params[:products] = [product.id, product2.id]
      expect(users).to contain_exactly(owner, owner2, purchaser, purchaser2)
    end
  end

  context "when searching for authorized_users" do
    let(:authorized_users) { FactoryBot.create_list(:user, 3) }
    let(:user) { authorized_users.first }
    let(:user2) { authorized_users.second }
    let(:user3) { authorized_users.third }
    let(:user4) { FactoryBot.create(:user) }

    before :each do
      product.update_attributes(requires_approval: true)
      product2.update_attributes(requires_approval: true)
      product3.update_attributes(requires_approval: false)
      # Users 1 and 2 have access to product1
      # Users 2 and 3 have access to product2
      # User 4 has access to product3, which is inactive and requires no approval
      ProductUser.create(product: product, user: user, approved_by: owner.id, approved_at: Time.current)
      ProductUser.create(product: product, user: user2, approved_by: owner.id, approved_at: Time.current)
      ProductUser.create(product: product2, user: user2, approved_by: owner.id, approved_at: Time.current)
      ProductUser.create(product: product2, user: user3, approved_by: owner.id, approved_at: Time.current)
      ProductUser.create(product: product3, user: user4, approved_by: owner.id, approved_at: Time.current)
      params[:bulk_email].merge!(user_types: [:authorized_users])
    end

    it_behaves_like "active/inactive users"

    context "when specifying no specific instrument" do
      before { params[:products] = [] }

      it "returns all authorized users for any active instrument with an access list" do
        expect(users).to match_array(authorized_users)
      end
    end

    context "when specifying the first instrument" do
      before { params[:products] = [product.id] }

      it "returns only the users authorized for the first instrument" do
        expect(users)
          .to contain_exactly(authorized_users.first, authorized_users.second)
      end
    end

    context "when specifying the second instrument" do
      before { params[:products] = [product2.id] }

      it "returns only the users authorized for the second product" do
        expect(users)
          .to contain_exactly(authorized_users.second, authorized_users.third)
      end
    end

    context "when specifying the the first and second instruments" do
      before { params[:products] = [product.id, product2.id] }

      it "returns only the users for both products and no more" do
        expect(users).to match_array(authorized_users)
      end
    end
  end

  context "when searching for customers and authorized_users" do
    before(:each) do
      params[:bulk_email][:user_types] = %i(authorized_users customers)
      params[:products] = [product.id]
    end

    context "when a user is both a customer and authorized_user" do
      before(:each) do
        ProductUser.create(product: product, user: purchaser, approved_by: 1)
        place_order(purchaser: purchaser, product: product, account: account)
      end

      it "returns the user only once" do
        expect(users).to contain_exactly(purchaser)
      end
    end
  end

  # SLOW
  # Oracle blows up if you do a WHERE IN (...) clause with more than a 1000 items
  # so let's test it.
  # commented out because the creation of users takes so long. run it every once in a while
  # describe "being ready for Oracle" do
  #   before :each do
  #     Array.new(1001) do
  #       user = FactoryBot.create(:user)
  #       od = place_product_order(user, facility, product, account)
  #     end
  #     expect(OrderDetail.all.size).to eq(1001)
  #   end
  #   it "returns 1001 users" do
  #     users = @controller.do_search(@params)
  #     expect(users.size).to eq(1001)
  #   end
  # end
end
