# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionsController do
  let(:params) { {} }
  let(:product) { FactoryBot.create(:setup_item, :with_facility_account) }
  let(:user) { FactoryBot.create(:user) }

  describe "GET #in_review", billing_review_period: 7.days do

    before(:each) do
      sign_in user
      get action, params: params
    end

    let(:action) { :in_review }

    context "when the user owns multiple accounts" do
      let!(:accounts) do
        FactoryBot.create_list(:setup_account,
                               2,
                               :with_order,
                               product: product,
                               owner: user)
      end
      let(:order_details) { accounts.flat_map(&:order_details) }

      before(:each) do
        order_details.each do |order_detail|
          order_detail.reviewed_at = reviewed_at
          order_detail.to_complete!
        end
      end

      context "when reviewed_at is in the future" do
        let(:reviewed_at) { 1.day.from_now }

        it "sets order_details to orders in review from all owned accounts", :aggregate_failures do
          expect(assigns(:order_details)).to match_array(order_details)
          expect(assigns(:recently_reviewed)).to be_empty
        end
      end

      context "when reviewed_at is in the past" do
        let(:reviewed_at) { 1.day.ago }

        it "sets recently_reviewed to orders reviewed from all owned accounts", :aggregate_failures do
          expect(assigns(:order_details)).to be_empty
          expect(assigns(:recently_reviewed)).to eq(order_details)
        end
      end

    end

  end

  context "mark as reviewed" do
    let(:facility) { FactoryBot.create(:facility) }
    let(:account) { FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user)) }
    let(:order_detail1) { place_and_complete_item_order(user, facility, account) }
    let(:order_detail2) { place_and_complete_item_order(user, facility, account) }
    let(:account2) { FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user)) }
    let(:order_detail3) { place_and_complete_item_order(user, facility, account2) }

    before :each do
      sign_in user
    end

    context "with a 1 week review period", billing_review_period: 7.days do
      it "updates" do
        params = { facility_id: facility.url_name, order_detail_ids: [order_detail1.id, order_detail3.id] }
        post :mark_as_reviewed, params: params
        expect(flash[:error]).to be_nil
        expect(assigns(:order_details_updated)).to eq([order_detail1, order_detail3])
        expect(order_detail1.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
        expect(order_detail3.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
      end

      it "logs the order when it gets review" do
        params = { facility_id: facility.url_name, order_detail_ids: [order_detail1.id, order_detail3.id] }
        post :mark_as_reviewed, params: params
        expect(LogEvent.find_by(loggable: order_detail1, event_type: :review)).to be_present
        expect(LogEvent.find_by(loggable: order_detail3, event_type: :review)).to be_present
      end

      it "displays an error for no orders" do
        params = { facility_id: facility.url_name }
        post :mark_as_reviewed, params: params
        expect(flash[:error]).to include("No orders")
      end
    end
  end
end
