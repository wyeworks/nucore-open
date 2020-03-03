# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

def it_should_find_the_order(desc = "")
  it "should find the order " + desc do
    get :index, params: { search: order.id.to_s }
    expect(order_detail_results).to eq([order_detail])
  end
end

def it_should_not_find_the_order(desc = "")
  it "should not find the order " + desc do
    get :index, params: { search: order.id.to_s }
    expect(order_detail_results).to be_empty
  end
end

def it_should_have_admin_edit_paths
  render_views
  it "should have link to the admin path" do
    get :index, params: { search: order.id.to_s }
    expect(response.body).to include facility_order_path(order_detail.facility, order_detail.order)
  end
end

def it_should_have_customer_paths
  render_views
  it "should have links to the customer view" do
    get :index, params: { search: order.id.to_s }
    expect(response.body).to include order_order_detail_path(order_detail.order, order_detail)
    expect(response.body).to include order_path(order)
  end
end

RSpec.describe GlobalSearchController do
  before(:all) { create_users }
  let!(:product) { FactoryBot.create(:setup_item) }
  let!(:order) { FactoryBot.create(:purchased_order, product: product) }
  let!(:order_detail) { order.order_details.first }
  let!(:facility) { order.facility }
  let(:order_detail_results) { assigns[:searchers].find { |s| s.template == "order_details" }.results }
  let(:statement_results) { assigns[:searchers].find { |s| s.template == "statements" }.results }
  let(:product_results) { assigns[:searchers].find { |s| s.template == "products" }.results }

  describe "index" do
    before do
      allow(FullTextSearch::Model).to receive(:full_text_searcher).and_return(FullTextSearch::LikeSearcher)
    end

    context "when not signed in" do
      it "can search with the product searcher", :aggregate_failures do
        get :index, params: { search: product.name }

        expect(assigns[:searchers].map(&:class)).to include(GlobalSearch::ProductSearcher)
        expect(product_results).to include(product)
      end

      it "does not search with the order searcher" do
        get :index, params: { search: order.id.to_s }

        expect(assigns[:searchers].map(&:class)).not_to include(GlobalSearch::OrderSearcher)
      end
    end

    context "when acting as another user" do
      before do
        allow_any_instance_of(GlobalSearchController).to receive(:acting_as?).and_return(true)
      end

      it "can search with the product searcher", :aggregate_failures do
        get :index, params: { search: product.name }

        expect(assigns[:searchers].map(&:class)).to include(GlobalSearch::ProductSearcher)
        expect(product_results).to include(product)
      end

      it "does not search with the order searcher" do
        get :index, params: { search: order.id.to_s }

        expect(assigns[:searchers].map(&:class)).not_to include(GlobalSearch::OrderSearcher)
      end
    end

    context "signed in as a normal user" do
      before :each do
        sign_in @guest
      end

      context "when it is purchased for the user" do
        before :each do
          order.update_attributes(user: @guest)
        end

        it_should_find_the_order
        it_should_have_customer_paths
      end

      context "when it is purchased for another user" do
        before :each do
          order.update_attributes(user: @admin)
        end

        it_should_not_find_the_order
      end
    end

    context "when signed in as a facility staff" do
      before :each do
        grant_role(@staff, facility)
        sign_in @staff
      end

      it_should_find_the_order "even if it is under a different user"
      it_should_have_admin_edit_paths
    end

    context "when signed in as facility admin for a different facility" do
      let(:facility2) { FactoryBot.create :facility }
      before :each do
        grant_role(@staff, facility2)
        sign_in @staff
      end

      it_should_not_find_the_order
    end

    context "when signed in as facility admin, but order was placed for the user in a different facility" do
      let(:facility2) { FactoryBot.create :setup_facility }
      let!(:product) { FactoryBot.create(:setup_item, facility: facility2) }
      let!(:order) { FactoryBot.create(:purchased_order, product: product) }
      let!(:order_detail) { order.order_details.first }
      let(:user) { order.user }
      before :each do
        grant_role user, facility
        sign_in user
      end

      it_should_find_the_order
      it_should_have_customer_paths
    end

    context "when signed in as a global billing administrator", feature_setting: { global_billing_administrator: true } do
      before { sign_in create(:user, :global_billing_administrator) }

      it_should_find_the_order
      it_should_have_admin_edit_paths
    end

    describe "account roles" do
      let(:account) { order_detail.account }
      context "when signed in as a business admin" do
        before :each do
          sign_in @staff
          AccountUser.grant(@staff, AccountUser::ACCOUNT_ADMINISTRATOR, account, by: @admin)
        end

        it_should_find_the_order
        it_should_have_customer_paths
      end

      context "when signed in as a purchaser" do
        before :each do
          sign_in @staff
          AccountUser.grant(@staff, AccountUser::ACCOUNT_PURCHASER, account, by: @admin)
        end

        it_should_not_find_the_order
      end

      context "when signed in as an account owner" do
        before :each do
          sign_in @staff
          AccountUser.grant(@staff, AccountUser::ACCOUNT_OWNER, account, by: @admin)
        end

        it_should_find_the_order
        it_should_have_customer_paths
      end
    end

    context "signed in as admin" do
      before :each do
        sign_in @admin
      end

      it "should not return an unpurchased order" do
        order2 = FactoryBot.create(:setup_order, product: product)
        get :index, params: { search: order2.id.to_s }
        expect(order_detail_results).to be_empty
      end

      it_should_find_the_order
      it_should_have_admin_edit_paths

      it "should return the order detail with the id" do
        get :index, params: { search: order_detail.id.to_s }
        expect(order_detail_results).to match_array([order_detail])
      end

      context "when including the dash" do
        before :each do
          get :index, params: { search: order_detail.to_s }
        end

        it "should redirect to order detail" do
          expect(order_detail_results).to eq([order_detail])
        end
      end

      context "when searching by external id" do
        let(:external_id) { "CX-2323" }
        let!(:external_service_receiver) { create :external_service_receiver, external_id: external_id }

        it "finds the correct order detail and renders the index page" do
          get :index, params: { search: external_id }
          expect(order_detail_results).to eq [external_service_receiver.receiver]
        end
      end

      describe "when searching for a statement", if: Account.config.statements_enabled? do
        let!(:statement) { FactoryBot.create(:statement, created_by_user: create(:user)) }

        it "finds it by the invoice number" do
          get :index, params: { search: statement.invoice_number }
          expect(statement_results).to eq([statement])
        end

        it "finds it by the id" do
          get :index, params: { search: statement.id }
          expect(statement_results).to eq([statement])
        end

        it "does not find it by the wrong invoice number" do
          get :index, params: { search: "0-123" }
          expect(statement_results).to be_empty
        end
      end
    end
  end
end
