# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityJournalsController do
  let(:account) { @account }
  let(:admin_user) { @admin }
  let(:facility) { @authable }
  let(:user) { @user }
  let(:journal) { @journal }

  include DateHelper

  render_views

  def create_order_details
    @user = create(:user)
    @order_detail1 = place_and_complete_item_order(user, facility, account, true)
    @order_detail2 = place_and_complete_item_order(user, facility, account)
    # make sure order detail 2 is not reviewed (it is if a zero day review period)
    @order_detail2.update_attributes(reviewed_at: nil)

    @account2 = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: user), facility_id: facility.id)
    @authable_account2 = FactoryBot.create(:facility_account, facility: facility)
    @order_detail3 = place_and_complete_item_order(user, facility, @account2, true)

    [@order_detail1, @order_detail3].each do |od|
      od.update_attribute(:reviewed_at, 1.day.ago)
    end
  end

  before(:all) { create_users }

  before(:each) do
    @authable = create(:facility)
    @account = create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @admin), facility_id: facility.id)
    @journal = create(:journal, facility: facility, created_by: @admin.id, journal_date: 2.days.ago.change(usec: 0))
  end

  describe "#index" do
    before :each do
      @method = :get
      @action = :index
      @params = { facility_id: facility.url_name }
      @pending_journal = create(:journal, facility: facility, created_by: @admin.id, journal_date: Time.zone.now, is_successful: nil)
    end

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only do
      expect(response).to be_successful
      expect(assigns(:pending_journals)).to eq([@pending_journal])
    end
  end

  describe "#update" do
    before :each do
      @method = :put
      @action = :update
      @params = { facility_id: facility.url_name, id: @journal.id, journal: { reference: "REFERENCE NUMBER" } }
      @journal.update_attribute(:is_successful, nil)
    end

    it_should_allow_managers_only {}
    it_should_deny_all [:staff, :senior_staff]

    context "signed in" do
      before :each do
        grant_and_sign_in @director
        ignore_account_validations
        create_order_details
        @creation_errors = @journal.create_journal_rows!([@order_detail1, @order_detail3])
        @journal.create_spreadsheet if Settings.financial.journal_format.xls
      end

      it "is set up properly" do
        expect(@creation_errors).to be_empty
        expect(@order_detail1.reload.journal_id).not_to be_nil
        expect(@order_detail3.reload.journal_id).not_to be_nil
        expect(@journal.order_details.distinct.size).to eq(2)
        expect(@journal.is_successful).to be_nil
      end

      it "shows an error if journal_status is blank" do
        do_request
        expect(flash[:error]).to include "Please select a journal status"
      end

      it "throws an error if :reference is empty" do
        @params[:journal_status] = "succeeded"
        @params[:journal][:reference] = ""

        do_request
        expect(flash[:error]).to include "Reference may not be blank"
      end

      it "leaves success as nil" do
        do_request
        expect(@journal.reload.is_successful).to be_nil
      end

      context "successful journal" do
        before :each do
          @params[:journal_status] = "succeeded"
          do_request
        end

        it "has no errors" do
          expect(assigns[:journal].errors).to be_empty
          expect(flash[:error]).to be_nil
        end

        it "sets updated_by to the logged in user and leaves created_by alone" do
          expect(assigns[:journal].updated_by).to eq(@director.id)
          expect(assigns[:journal].created_by).to eq(@admin.id)
        end

        it "has an is_successful value of true" do
          expect(assigns[:journal].is_successful?).to be true
          expect(assigns[:journal]).to be_successful
        end

        it "sets all order details to reconciled" do
          reconciled = OrderStatus.reconciled
          expect(@order_detail1.reload.order_status).to eq(reconciled)
          expect(@order_detail3.reload.order_status).to eq(reconciled)
        end

        it "sets the reconciled_at for all order details to the journal date", :time_travel do
          expect(@order_detail1.reload.reconciled_at).to eq(@journal.journal_date)
          expect(@order_detail3.reload.reconciled_at).to eq(@journal.journal_date)
        end
      end

      context "successful with errors" do
        before :each do
          @params[:journal_status] = "succeeded_errors"
          do_request
        end

        it "has no errors" do
          expect(assigns[:pending_journal].errors).to be_empty
          expect(flash[:error]).to be_nil
        end

        it "sets updated_by to the logged in user and leaves created_by alone" do
          expect(assigns[:journal].updated_by).to eq(@director.id)
          expect(assigns[:journal].created_by).to eq(@admin.id)
        end

        it "has an is_successful value of true" do
          expect(assigns[:journal].is_successful).to be true
          expect(assigns[:journal]).to be_successful
        end

        it "leaves the order statuses as complete" do
          completed_status = OrderStatus.complete
          expect(@order_detail1.reload.order_status).to eq(completed_status)
          expect(@order_detail3.reload.order_status).to eq(completed_status)
        end
      end

      context "failed journal" do
        before :each do
          @params[:journal_status] = "failed"
          do_request
        end

        it "has no errors" do
          expect(assigns[:journal].errors).to be_empty
          expect(flash[:error]).to be_nil
        end

        it "sets updated_by to the logged in user and leaves created_by alone" do
          expect(assigns[:journal].updated_by).to eq(@director.id)
          expect(assigns[:journal].created_by).to eq(@admin.id)
        end

        it "has a successful value of false" do
          expect(assigns[:journal].is_successful).not_to be_nil
          expect(assigns[:journal].is_successful).to be false
          expect(assigns[:journal]).not_to be_successful
        end

        context "when reloading from the database" do
          it "still has a successful value of false" do
            expect(@journal.reload.is_successful).not_to be_nil
            expect(@journal.reload.is_successful).to be false
            expect(assigns[:journal].reload).not_to be_successful
          end
        end

        it "sets all journal ids to nil for all order_details in a failed journal" do
          expect(@order_detail1.reload.journal_id).to be_nil
          expect(@order_detail3.reload.journal_id).to be_nil
        end
      end
    end
  end

  describe "#create" do
    let(:journal_date) { I18n.l(Time.zone.today, format: :usa) }

    before :each do
      @method = :post
      @action = :create
      @params = {
        facility_id: facility.url_name,
        journal_date: journal_date,
      }
    end

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only :redirect, "and respond gracefully when no order details given" do |_user|
      journal_date = parse_usa_date(@journal_date)
      expect(flash[:error]).not_to be_nil
    end

    context "validations" do
      shared_examples_for "journal error" do |error_message|
        it "does not create a journal" do
          expect { do_request }.not_to change(Journal, :count)
        end

        it "does not persist the journal" do
          do_request
          expect(assigns(:journal)).not_to be_persisted
        end

        it "has an error" do
          do_request
          expect(assigns(:journal).errors.full_messages.join).to match /#{error_message}/i
        end
      end

      before :each do
        ignore_account_validations
        create_order_details
        @params[:order_detail_ids] = [@order_detail1.id, @order_detail3.id]
        sign_in @admin
      end

      context "when it is successful" do
        it "creates a new journal" do
          expect { do_request }.to change(Journal, :count).by(1)
        end
      end

      context "when the journal_date is blank" do
        let(:journal_date) { "" }

        it_behaves_like "journal error", "may not be blank"
      end

      context "when the journal_date is in MM/YY/DD format" do
        let(:journal_date) { "1/1/11" }

        it_behaves_like "journal error", "must be in MM/DD/YYYY format"
      end

      it "throttles the error message size" do
        msgs = []
        err = ""
        500.times { err += "x" }
        10.times { msgs << err }
        errors = double "ActiveModel::Errors", full_messages: msgs
        allow_any_instance_of(Journal).to receive(:errors).and_return errors
        allow_any_instance_of(Journal).to receive(:save).and_return false
        do_request
        expect(response).to redirect_to new_facility_journal_path
        expect(flash[:error]).to be_present
        expect(flash[:error].length).to be < 4000
        expect(flash[:error]).to end_with I18n.t "controllers.facility_journals.create.more_errors"
      end

      context "order detail is already journaled" do
        before :each do
          journal = create(:journal)
          @params[:order_detail_ids] = [@order_detail1.id]
          @order_detail1.update_attributes(journal_id: journal.id)
        end

        # order details that have journal id already set are filtered out in #order_detail_for_creation
        it_behaves_like "journal error", "No orders were selected to journal"
      end

      context "spans fiscal year", feature_setting: { journals_may_span_fiscal_years: false } do
        before :each do
          @order_detail1.update_attributes(fulfilled_at: SettingsHelper.fiscal_year_end - 1.day)
          @order_detail3.update_attributes(fulfilled_at: SettingsHelper.fiscal_year_end + 1.day)
        end

        it_behaves_like "journal error", "Journals may not span multiple fiscal years."
      end

      context "trying to journal in the future" do
        before :each do
          @params[:journal_date] = format_usa_date(1.day.from_now)
        end

        it_behaves_like "journal error", "Journal Date may not be in the future"
      end

      context "trying to put journal date before fulfillment date" do
        before :each do
          @order_detail1.update_attributes(fulfilled_at: 5.days.ago)
          @order_detail3.update_attributes(fulfilled_at: 3.days.ago)
          @params[:journal_date] = format_usa_date(4.days.ago)
        end

        it_behaves_like "journal error", "Journal Date may not be before the latest fulfillment date."

        it "does allow to be the same day" do
          @params[:journal_date] = format_usa_date(3.days.ago)
          do_request
          expect(assigns(:journal)).to be_persisted
        end
      end

      context "when the account is not open" do
        let(:fulfilled_at) { @order_detail.fulfilled_at.change(usec: 0) }

        before(:each) do
          @params[:order_detail_ids] = [@order_detail.id]

          expect_any_instance_of(ValidatorFactory.validator_class)
            .to receive(:account_is_open!)
            .with(fulfilled_at)
            .and_raise(ValidatorError, "Not open")
        end

        it_behaves_like "journal error", "is invalid. Not open"
      end
    end

    context "in cross facility", feature_setting: { global_billing_administrator: true } do
      before :each do
        @params[:facility_id] = "all"
        sign_in create(:user, :global_billing_administrator)
        do_request
      end

      it "renders a 404" do
        expect(response.code).to eq("404")
      end
    end
  end

  describe "#show" do
    before :each do
      @method = :get
      @action = :show
      @params = { facility_id: facility.url_name, id: @journal.id }
    end

    it_should_allow_managers_only
    it_should_deny_all [:staff, :senior_staff]
  end

  describe "#new" do
    let(:expiry_date) { Time.zone.now - 1.year }
    let(:user) { FactoryBot.create(:user) }
    let(:expired_payment_source) { create(:nufs_account, expires_at: expiry_date, account_users_attributes: account_users_attributes_hash(user: user), facility_id: facility.id) }
    let!(:problem_order_detail) { place_and_complete_item_order(user, facility, expired_payment_source, true) }

    before :each do
      @method = :get
      @action = :new
      @params = { facility_id: facility.url_name }
      ignore_account_validations
      create_order_details
    end

    it_should_deny_all [:staff, :senior_staff]

    it_should_allow_managers_only do
      expect(response).to be_successful
    end

    it "sets appropriate values" do
      sign_in @admin
      do_request
      expect(response).to be_successful
      expect(assigns(:order_details)).to contain_all([@order_detail1, @order_detail3, problem_order_detail])
      expect(assigns(:order_detail_action)).to eq(:create)
    end

    it "does not have different values if there is a pending journal" do
      # create and populate a journal
      @pending_journal = create(:journal, facility_id: facility.id, created_by: @admin.id, journal_date: Time.zone.now, is_successful: nil)
      @order_detail4 = place_and_complete_item_order(user, facility, account)

      @pending_journal.create_journal_rows!([@order_detail4])

      sign_in @admin
      do_request
      expect(assigns(:order_details)).to contain_all [@order_detail1, @order_detail3, problem_order_detail]
      expect(assigns(:order_detail_action)).to be_nil
    end

    context "in cross facility", feature_setting: { global_billing_administrator: true } do
      before :each do
        @params[:facility_id] = "all"
        sign_in create(:user, :global_billing_administrator)
        do_request
      end

      it "renders a 404" do
        expect(response.code).to eq("404")
      end
    end
  end

  describe "#reconcile" do
    def perform
      post :reconcile, params: { facility_id: facility.url_name, order_detail: order_detail_params, journal_id: journal.id }
    end

    before do
      sign_in admin_user
      ignore_account_validations
      create_order_details
      @journal.create_journal_rows!([@order_detail1, @order_detail3])
    end

    describe "submitting a single order detail" do
      let(:order_detail_params) do
        {
          @order_detail1.id.to_s => { reconciled: "1" },
          @order_detail3.id.to_s => { reconciled: "0" },
        }
      end

      it "sets it to reconciled" do
        expect { perform }.to change { @order_detail1.reload.state }.to eq("reconciled")
      end

      it "does not reconcile the one not selected" do
        expect { perform }.not_to change { @order_detail3.reload.state }
      end

      it "sets the reconciled_at to the journal date" do
        expect { perform }.to change { @order_detail1.reload.reconciled_at }
          .to(journal.journal_date)
      end
    end

    describe "when submitting an order detail on another journal" do
      let(:journal2) { create(:journal, facility: facility, created_by: @admin.id, journal_date: 2.days.ago) }
      before { journal2.create_journal_rows!([@order_detail2]) }

      let(:order_detail_params) do
        {
          @order_detail1.id.to_s => { reconciled: "1" },
          @order_detail2.id.to_s => { reconciled: "1" },
        }
      end

      it "does not reconcile either" do
        perform
        expect(@order_detail1.reload.state).to eq("complete")
        expect(@order_detail2.reload.state).to eq("complete")
      end
    end

    describe "when submitting nothing checked" do
      let(:order_detail_params) do
        {
          @order_detail1.id.to_s => { reconciled: "0" },
          @order_detail3.id.to_s => { reconciled: "0" },
        }
      end

      it "sets a flash message" do
        perform
        expect(flash[:error]).to include("No orders")
      end
    end
  end

end
