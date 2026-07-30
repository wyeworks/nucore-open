# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe TimedServicesController, type: :controller do
  render_views

  let(:facility) { create(:setup_facility) }
  let(:timed_service) { create(:timed_service, facility:) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @params = { id: timed_service.url_name, facility_id: facility.url_name }
  end

  describe "new" do
    before :each do
      @method = :get
      @action = :new
      @params.delete(:id)
    end

    context "as administrator" do
      let(:user) { create(:user, :administrator) }

      it "offers the duration pricing mode" do
        sign_in user
        do_request

        expect(response.body).to include(%(value="#{TimedService::Pricing::DURATION}"))
      end
    end

    context "as facility director" do
      let(:user) { create(:user, :facility_director, facility:) }

      it "does not offer the duration pricing mode" do
        sign_in user
        do_request

        expect(response.body).to include(%(value="#{TimedService::Pricing::STANDARD}"))
        expect(response.body).not_to include(%(value="#{TimedService::Pricing::DURATION}"))
      end
    end
  end

  describe "update" do
    before :each do
      @method = :put
      @action = :update
      @params[:timed_service] = { pricing_mode: TimedService::Pricing::DURATION }
    end

    shared_examples "pricing mode is immutable" do
      it "does not change the pricing mode after creation" do
        sign_in(user)

        expect { do_request }.not_to change { timed_service.reload.pricing_mode }
        expect(timed_service.reload).not_to be_duration_pricing_mode
      end
    end

    context "as facility admin" do
      let(:user) { create(:user, :facility_administrator, facility:) }

      include_examples "pricing mode is immutable"
    end

    context "as administrator" do
      let(:user) { create(:user, :administrator) }

      include_examples "pricing mode is immutable"
    end
  end

  describe "manage" do
    before :each do
      @method = :get
      @action = :manage
    end

    let(:user) { create(:user, :facility_administrator, facility:) }

    context "in duration pricing mode" do
      let(:timed_service) do
        create(:timed_service, facility:, pricing_mode: TimedService::Pricing::DURATION)
      end

      it "shows the duration pricing mode" do
        sign_in user
        do_request

        expect(response.body).to include(">Duration<")
      end
    end

    context "in standard pricing mode" do
      it "labels the mode rather than showing the raw column value" do
        sign_in user
        do_request

        expect(response.body).to include(">Standard<")
        expect(response.body).not_to include(">Schedule Rule<")
      end
    end
  end

  describe "create" do
    before :each do
      @method = :post
      @action = :create
    end

    describe "duration billing permissions" do
      before do
        @params[:timed_service] = attributes_for(
          :timed_service,
          pricing_mode: TimedService::Pricing::DURATION,
          facility_account_id: facility.facility_accounts.first.id,
        )
      end

      shared_examples "duration billing creation disallowed" do
        it "does not allow user to create duration billing timed service" do
          sign_in(user)

          expect { do_request }.to_not change { TimedService.count }
          expect(@response.body).to(
            include(I18n.t("controllers.timed_services.create.duration_billing_not_authorized"))
          )
        end
      end

      context "as facility admin" do
        let(:user) { create(:user, :facility_administrator, facility:) }

        include_examples "duration billing creation disallowed"
      end

      context "as facility director" do
        let(:user) { create(:user, :facility_director, facility:) }

        include_examples "duration billing creation disallowed"
      end

      context "as administrator" do
        let(:user) { create(:user, :administrator) }

        it "allows to create a duration billing timed service" do
          sign_in user

          expect { do_request }.to change { TimedService.count }.by(1)
          expect(assigns(:product)).to be_duration_pricing_mode
        end
      end
    end

    describe "standard pricing" do
      before do
        @params[:timed_service] = attributes_for(
          :timed_service,
          facility_account_id: facility.facility_accounts.first.id,
        )
      end

      context "as facility admin" do
        let(:user) { create(:user, :facility_administrator, facility:) }

        it "allows to create a standard timed service" do
          sign_in user

          expect { do_request }.to change { TimedService.count }.by(1)
          expect(assigns(:product)).not_to be_duration_pricing_mode
        end
      end
    end
  end
end
