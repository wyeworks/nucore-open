# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchController do
  render_views

  let(:facility) { FactoryBot.create(:setup_facility) }
  let!(:user) { FactoryBot.create(:user, first_name: "Firstname", last_name: "Lastname") }

  shared_examples_for "searching" do |action|
    let(:session_user) { FactoryBot.create(:user, :facility_administrator, facility: facility) }
    let(:params) { {} }
    before do
      sign_in session_user
      post :user_search_results, params: params.merge(search_type: action, search_term: user.username)
    end

    it "#{action} finds the user" do
      expect(response.body).to include(user.email)
      expect(response.body).to include(user.first_name)
      expect(response.body).to include(user.last_name)
    end

    it "#{action} renders the link" do
      expect(response).to render_template("search/_#{action}_link")
    end
  end

  describe "user_search_results" do
    it "does not allow a non-logged in user" do
      get :user_search_results
      expect(response.code).to redirect_to(new_user_session_path)
    end

    it_behaves_like "searching", "account_account_user" do
      let(:account) { FactoryBot.create(:setup_account) }
      let(:params) { { account_id: account.id } }
    end

    describe "facility_account_account_user", feature_setting: { "accounts.edit_accounts" => true, reload_routes: true } do
      it_behaves_like "searching", "facility_account_account_user" do
        let(:account) { FactoryBot.create(:setup_account) }
        let(:params) { { account_id: account.id } }
      end
    end

    # This is safe for a non-admin to see because the links themselves are protected
    it_behaves_like "searching", "global_user_role"

    it_behaves_like "searching", "manage_user" do
      let(:params) { { facility_id: facility.id } }

      it "has order for" do
        expect(response.body).to include("Order For")
      end
    end

    it_behaves_like "searching", "map_user"

    describe "user_new_account", feature_setting: { "accounts.edit_accounts" => true, reload_routes: true } do
      it_behaves_like "searching", "user_new_account"
    end

    it_behaves_like "searching", "user_price_group_member" do
      let(:price_group) { FactoryBot.create(:price_group, facility: facility) }
      let(:params) { { price_group_id: price_group.id } }
    end

    it_behaves_like "searching", "user_product_approval" do
      let(:product) { FactoryBot.create(:setup_item, facility: facility) }
      let(:params) { { product_id: product.id } }
    end
  end
end
