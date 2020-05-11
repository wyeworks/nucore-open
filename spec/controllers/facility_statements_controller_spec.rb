# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

if Account.config.statements_enabled?
  RSpec.shared_examples "it sets up order_detail and creates statements" do
    it "sets up order_detail and creates statements" do
      expect(@order_detail1.reload.reviewed_at).to be < Time.zone.now
      expect(@order_detail1.statement).to be_nil
      expect(@order_detail1.price_policy).not_to be_nil
      expect(@order_detail1.account.type).to eq(@account_type)
      expect(@order_detail1.dispute_at).to be_nil

      grant_and_sign_in(@user)
      do_request
      expect(flash[:error]).to be_nil
      expect(response).to redirect_to action: :new
    end
  end

  RSpec.describe FacilityStatementsController do
    render_views

    def create_order_details
      @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
      @order_detail2 = place_and_complete_item_order(@user, @authable, @account)
      @order_detail2.update_attributes(reviewed_at: nil)

      @account2 = FactoryBot.create(@account_sym, :with_account_owner, owner: @user, facility: @authable)
      @authable_account2 = FactoryBot.create(:facility_account, facility: @authable)
      @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)

      [@order_detail1, @order_detail3].each do |od|
        od.reviewed_at = 1.day.ago
        od.save!
      end
    end

    before(:all) do
      create_users
      @account_type = Account.config.statement_account_types.first
      @account_sym = @account_type.underscore.to_sym
    end

    before(:each) do
      @authable = FactoryBot.create(:facility)
      @other_facility = FactoryBot.create(:facility)
      @user = FactoryBot.create(:user)
      @other_user = FactoryBot.create(:user)
      UserRole.grant(@user, UserRole::ADMINISTRATOR)
      @account = FactoryBot.create(@account_sym, account_users_attributes: account_users_attributes_hash(user: @user), facility: @authable)
      @other_account = FactoryBot.create(@account_sym, account_users_attributes: account_users_attributes_hash(user: @other_user), facility: @other_facility)
      @statement = FactoryBot.create(:statement, facility_id: @authable.id, created_by: @admin.id, account: @account)
      @statement2 = FactoryBot.create(:statement, facility_id: @other_facility.id, created_by: @admin.id, account: @other_account)
      @params = { facility_id: @authable.url_name }
    end

    context "index" do

      before :each do
        @method = :get
        @action = :index
      end

      it_should_allow_managers_only do
        expect(assigns(:statements).size).to eq(1)
        expect(assigns(:statements)[0]).to eq(@statement)
        is_expected.not_to set_flash
      end

      it_should_deny_all [:staff, :senior_staff]

      context "when user is billing admin" do
        let(:billing_admin) { create(:user) }

        before do
          UserRole.grant(billing_admin, UserRole::GLOBAL_BILLING_ADMINISTRATOR)
          sign_in billing_admin
          get :index, params: { facility_id: "all" }
        end

        it "allows access" do
          expect(response.code).to eq("200")
          is_expected.not_to set_flash
        end

        it "shows all statements" do
          expect(assigns(:statements).size).to eq(2)
          expect(assigns(:statements)).to match_array([@statement, @statement2])
        end
      end
    end

    context "new" do
      before :each do
        @method = :get
        @action = :new
        create_order_details
      end

      it_should_allow_managers_only do
        expect(response).to be_successful
      end

      it_should_deny_all [:staff, :senior_staff]

      context "if set statement search start date feature is disabled", feature_setting: { set_statement_search_start_date: false } do
        it "should return the right order details without start date" do
          grant_and_sign_in(@user)
          do_request
          expect(response).to be_successful
          expect(assigns(:facility)).to eq(@authable)
          expect(assigns(:order_detail_action)).to eq(:create)
          expect(assigns(:order_details)).to contain_all [@order_detail1, @order_detail3]
        end
      end

      context "if set statement search start date feature is enabled", feature_setting: { set_statement_search_start_date: true } do
        it "should return the right order details with start date" do
          grant_and_sign_in(@user)
          do_request
          expect(response).to be_successful
          expect(assigns(:facility)).to eq(@authable)
          expect(assigns(:order_detail_action)).to eq(:create)
          expect(assigns(:order_details)).to contain_all [@order_detail1, @order_detail3]
        end
      end
    end

    context "create" do
      before :each do
        create_order_details
        @method = :post
        @action = :create
        @params.merge!(order_detail_ids: [@order_detail1.id, @order_detail3.id])
      end


      it_should_allow_managers_only :redirect do
        expect(response).to be_redirect
      end

      it_should_deny_all [:staff, :senior_staff]

      context "when statement emailing is on", feature_setting: { send_statement_emails: true } do
        include_examples "it sets up order_detail and creates statements"

        it "sends statements" do
          grant_and_sign_in(@user)

          expect { do_request }.to change(ActionMailer::Base.deliveries, :count).by(2)
        end
      end

      context "when statement emailing is off", feature_setting: { send_statement_emails: false } do
        include_examples "it sets up order_detail and creates statements"

        it "does not send statements" do
          grant_and_sign_in(@user)

          expect { do_request }.not_to change(ActionMailer::Base.deliveries, :count)
        end
      end

      context "with multiple payment sources", feature_setting: { send_statement_emails: true } do
        it "displays properly formatted flash message" do
          sign_in(@user)
          do_request
          expect(flash[:notice]).to start_with("Notifications sent successfully to:<br/>#{@account.account_list_item}<br")
        end
      end

      context "with multiple payment sources", feature_setting: { send_statement_emails: false } do
        it "displays properly formatted flash message" do
          sign_in(@user)
          do_request
          expect(flash[:notice]).to start_with("Statements made successfully for:<br/>#{@account.account_list_item}<br")
        end
      end

      context "errors" do
        it "should display an error for no orders" do
          @params[:order_detail_ids] = nil
          grant_and_sign_in(@user)
          do_request
          expect(flash[:error]).not_to be_nil
          expect(response).to redirect_to action: :new
        end
      end
    end

    context "show" do

      before :each do
        @method = :get
        @action = :show
        @params.merge!(id: @statement.id)
      end

      it_should_allow_managers_only { expect(assigns(:statement)).to eq(@statement) }

      it_should_deny_all [:staff, :senior_staff]

    end

  end
end
