# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityNotificationsController do

  before(:all) { create_users }
  render_views

  before :each do
    @authable = FactoryBot.create(:facility)
    @user = FactoryBot.create(:user)
    @account = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @params = { facility_id: @authable.url_name }

    @order_detail1 = place_and_complete_item_order(@user, @authable, @account)
    @order_detail2 = place_and_complete_item_order(@user, @authable, @account)

    @account2 = FactoryBot.create(:nufs_account, account_users_attributes: account_users_attributes_hash(user: @user))
    @order_detail3 = place_and_complete_item_order(@user, @authable, @account2)
  end

  shared_examples_for "zero-day review period" do
    context "with no review period", billing_review_period: 0.days do
      before(:each) do
        sign_in @admin
        do_request
      end

      it { expect(response.code).to eq("404") }
    end
  end

  describe "GET #index" do
    let!(:problem_order) do
      place_and_complete_item_order(@user, @authable, @account2).tap do |od|
        od.update!(price_policy: nil)
      end
    end

    before :each do
      @method = :get
      @action = :index
    end

    context "with a 1 week review period", billing_review_period: 7.days do
      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_managers_only do
        expect(assigns(:order_details)).to contain_exactly(@order_detail1, @order_detail2, @order_detail3)
        expect(assigns(:order_detail_action)).to eq(:send_notifications)
        is_expected.not_to set_flash
      end
    end

    include_examples "zero-day review period"
  end

  describe "POST #send_notifications" do
    before :each do
      Notifier.deliveries.clear
      @method = :post
      @action = :send_notifications
      @params.merge!(order_detail_ids: [@order_detail1.id, @order_detail2.id])
    end

    context "with a 1 week review period", billing_review_period: 7.days do
      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_managers_only :redirect do
        expect(assigns(:errors)).to be_empty
        expect(assigns(:accounts_to_notify)).to contain_exactly(@account.id)
        expect([@order_detail1, @order_detail2]).to be_all { |od| od.reload.reviewed_at > 6.days.from_now }

        expect(Notifier.deliveries.count).to eq(1)
      end

      context "multiple accounts" do
        before :each do
          @params.merge!(order_detail_ids: [@order_detail1.id, @order_detail2.id, @order_detail3.id])
        end

        it "logs every order detail" do
          do_request
          log_event1 = LogEvent.find_by(loggable: @order_detail1, event_type: :notify)
          log_event2 = LogEvent.find_by(loggable: @order_detail2, event_type: :notify)
          log_event3 = LogEvent.find_by(loggable: @order_detail3, event_type: :notify)
          expect([log_event1, log_event2, log_event3]).to be_present
        end

        it_should_allow_managers_only :redirect do
          expect(assigns(:errors)).to be_empty
          expect([@order_detail1, @order_detail2, @order_detail3]).to be_all { |od| od.reload.reviewed_at? }
          expect(assigns(:accounts_to_notify)).to contain_exactly(@account.id, @account2.id)
        end

        context "while signed in" do
          before(:each) { maybe_grant_always_sign_in(:admin) }

          let(:order_details) do
            @accounts.map do |account|
              place_and_complete_item_order(@user, @authable, account)
            end
          end

          it "sends one email for the two accounts" do
            expect { do_request }.to change { Notifier.deliveries.count }.by(1)
          end

          context "with fewer than 10 accounts" do
            it "displays the account list" do
              @accounts = FactoryBot.create_list(:nufs_account, 3, account_users_attributes: account_users_attributes_hash(user: @user))
              @params = { facility_id: @authable.url_name }

              @params[:order_detail_ids] = order_details.map(&:id)
              do_request
              is_expected.to set_flash
              expect(@accounts).to be_all do |account|
                flash[:notice].include? account.account_number
              end
            end
          end

          context "with more than 10 accounts" do
            it "displays a count of accounts" do
              @accounts = FactoryBot.create_list(:nufs_account, 11, account_users_attributes: account_users_attributes_hash(user: @user))
              @params = { facility_id: @authable.url_name }

              @params[:order_detail_ids] = order_details.map(&:id)
              do_request
              is_expected.to set_flash
              expect(flash[:notice]).to include("11 accounts")
            end
          end
        end
      end

      context "errors" do
        before(:each) do
          maybe_grant_always_sign_in(:admin)
          @params[:order_detail_ids] = order_detail_ids
          do_request
        end

        context "with an empty order_detail IDs parameter" do
          let(:order_detail_ids) { nil }

          it "errors with a redirect" do
            expect(flash[:error]).to include("No orders selected")
            expect(response).to be_redirect
          end
        end

        context "with a parameter for a nonexistent order_detail ID" do
          let(:order_detail_ids) { [0] }

          it { expect(flash[:error]).to match(/Order 0 .+ not found/) }
        end
      end
    end

    include_examples "zero-day review period"
  end

  describe "GET #in_review" do
    before :each do
      @method = :get
      @action = :in_review
      @order_detail1.reviewed_at = 7.days.from_now
      @order_detail1.save!
      @order_detail3.reviewed_at = 7.days.from_now
      @order_detail3.save!
    end

    context "with a 1 week review period", billing_review_period: 7.days do
      it_should_deny_all [:staff, :senior_staff]

      it_should_allow_managers_only do
        expect(assigns(:order_details) - [@order_detail1, @order_detail3]).to be_empty
        expect(assigns(:order_detail_action)).to eq(:mark_as_reviewed)
        is_expected.not_to set_flash
      end
    end

    include_examples "zero-day review period"
  end

  context "mark as reviewed" do
    before :each do
      @method = :post
      @action = :mark_as_reviewed
      maybe_grant_always_sign_in(:admin)
    end

    context "with a 1 week review period", billing_review_period: 7.days do
      it_should_deny_all [:staff, :senior_staff]

      it "updates" do
        @params[:order_detail_ids] = [@order_detail1.id, @order_detail3.id]
        do_request
        expect(flash[:error]).to be_nil
        expect(assigns(:order_details_updated)).to eq([@order_detail1, @order_detail3])
        expect(@order_detail1.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
        expect(@order_detail3.reload.reviewed_at.to_i).to eq(Time.zone.now.to_i)
      end

      it "logs the order when it gets review" do
        @params[:order_detail_ids] = [@order_detail1.id, @order_detail3.id]
        do_request
        log_event = LogEvent.find_by(loggable: @order_detail1, event_type: :review)
        log_event = LogEvent.find_by(loggable: @order_detail3, event_type: :review)
        expect(log_event).to be_present
      end

      it "displays an error for no orders" do
        do_request
        expect(flash[:error]).to include("No orders")
      end
    end

    include_examples "zero-day review period"
  end
end
