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
      @order_detail2.update(reviewed_at: nil)

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

      context "invoice_date field visibility" do
        let(:administrator) { create(:user, :administrator) }
        let(:billing_admin) { create(:user, :global_billing_administrator) }
        let(:regular_user) { create(:user) }

        before do
          UserRole.grant(regular_user, UserRole::FACILITY_DIRECTOR, @authable)
        end

        context "when user is administrator" do
          before do
            sign_in administrator
            do_request
          end

          it "makes can_set_invoice_date? available to view" do
            expect(controller.helpers.can_set_invoice_date?).to be true
          end
        end

        context "when user is global billing administrator" do
          before do
            sign_in billing_admin
            do_request
          end

          it "makes can_set_invoice_date? available to view" do
            expect(controller.helpers.can_set_invoice_date?).to be true
          end
        end

        context "when user is not administrator or billing admin" do
          before do
            sign_in regular_user
            do_request
          end

          it "makes can_set_invoice_date? return false" do
            expect(controller.helpers.can_set_invoice_date?).to be false
          end
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

          expect { do_request }.to(
            have_enqueued_mail(Notifier, :statement).twice
          )
        end
      end

      context "when statement emailing is off", feature_setting: { send_statement_emails: false } do
        include_examples "it sets up order_detail and creates statements"

        it "does not send statements" do
          grant_and_sign_in(@user)

          expect { do_request }.not_to have_enqueued_mail
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
          expect(flash[:notice]).to start_with("#{I18n.t("Statements")} made successfully for:<br/>#{@account.account_list_item}<br")
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

      context "with invoice_date" do
        let(:administrator) { create(:user, :administrator) }
        let(:billing_admin) { create(:user, :global_billing_administrator) }
        let(:regular_user) { create(:user) }
        let(:invoice_date_value) { 3.days.ago.to_date }
        let(:invoice_date) { invoice_date_value.strftime("%m/%d/%Y") }

        before do
          UserRole.grant(regular_user, UserRole::FACILITY_DIRECTOR, @authable)
          @order_detail1.update_column(:fulfilled_at, 5.days.ago)
          @order_detail3.update_column(:fulfilled_at, 5.days.ago)
        end

        context "when user is administrator" do
          before do
            sign_in administrator
            @params[:invoice_date] = invoice_date
          end

          it "accepts invoice_date parameter" do
            existing_ids = Statement.where(account: @account).pluck(:id)
            do_request
            statement = Statement.where(account: @account).where.not(id: existing_ids).first
            expect(statement.invoice_date).to eq(invoice_date_value)
          end
        end

        context "when user is global billing administrator" do
          before do
            sign_in billing_admin
            @params[:invoice_date] = invoice_date
          end

          it "accepts invoice_date parameter" do
            existing_ids = Statement.where(account: @account).pluck(:id)
            do_request
            statement = Statement.where(account: @account).where.not(id: existing_ids).first
            expect(statement.invoice_date).to eq(invoice_date_value)
          end
        end

        context "when user is not administrator or billing admin" do
          before do
            sign_in regular_user
            @params[:invoice_date] = invoice_date
          end

          it "ignores invoice_date parameter and uses default" do
            get :new, params: { facility_id: @authable.url_name }
            expect(controller.helpers.can_set_invoice_date?).to be false
            do_request
            # Find the statement created for the account used in this test
            statement = Statement.where(account: @account).order(created_at: :desc).first
            expect(statement).not_to be_nil
            expect(statement[:invoice_date]).to eq(Date.current)
            expect(statement.invoice_date).to eq(Date.current)
          end
        end

        context "when invoice_date is before fulfillment" do
          let(:bad_invoice_date) { 10.days.ago.to_date.strftime("%m/%d/%Y") }

          before do
            sign_in billing_admin
            @params[:invoice_date] = bad_invoice_date
          end

          it "shows an error and does not create a statement" do
            expect { do_request }.not_to change(Statement, :count)
            expect(flash[:error]).to be_present
          end
        end

        context "when invoice_date is not provided" do
          before do
            sign_in administrator
          end

          it "creates statement with default invoice_date" do
            do_request
            # Find the statement created for the account used in this test
            statement = Statement.where(account: @account).order(created_at: :desc).first
            expect(statement).not_to be_nil
            expect(statement[:invoice_date]).to eq(Date.current)
            expect(statement.invoice_date).to eq(Date.current)
          end
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

    context "with granular permissions", feature_setting: { granular_permissions: true } do
      let(:facility) { @authable }
      let(:permitted_user) { create(:user) }
      let(:unpermitted_user) { create(:user) }

      before do
        create(:facility_user_permission, user: permitted_user, facility:, billing_journals: true)
      end

      describe "GET #index" do
        it "allows a user with billing_journals permission" do
          sign_in permitted_user
          get :index, params: { facility_id: facility.url_name }
          expect(response).to be_successful
        end

        it "denies a user without billing_journals permission" do
          sign_in unpermitted_user
          expect { get :index, params: { facility_id: facility.url_name } }.to raise_error(CanCan::AccessDenied)
        end
      end

      describe "GET #new" do
        before { create_order_details }

        it "allows a user with billing_journals permission" do
          sign_in permitted_user
          get :new, params: { facility_id: facility.url_name }
          expect(response).to be_successful
        end

        it "denies a user without billing_journals permission" do
          sign_in unpermitted_user
          expect { get :new, params: { facility_id: facility.url_name } }.to raise_error(CanCan::AccessDenied)
        end
      end

      describe "POST #create" do
        before { create_order_details }

        it "allows a user with billing_journals permission" do
          sign_in permitted_user
          post :create, params: { facility_id: facility.url_name, order_detail_ids: [@order_detail1.id, @order_detail3.id] }
          expect(response).to redirect_to(action: :new)
        end

        it "denies a user without billing_journals permission" do
          sign_in unpermitted_user
          expect { post :create, params: { facility_id: facility.url_name } }.to raise_error(CanCan::AccessDenied)
        end
      end

      describe "GET #show" do
        it "allows a user with billing_journals permission" do
          sign_in permitted_user
          get :show, params: { facility_id: facility.url_name, id: @statement.id }
          expect(response).to be_successful
        end

        it "denies a user without billing_journals permission" do
          sign_in unpermitted_user
          expect { get :show, params: { facility_id: facility.url_name, id: @statement.id } }.to raise_error(CanCan::AccessDenied)
        end
      end
    end

  end
end
