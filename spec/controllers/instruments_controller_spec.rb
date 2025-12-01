# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe InstrumentsController, type: :controller do
  render_views

  let(:facility) { create(:setup_facility) }
  let(:instrument) { create(:instrument, facility:, no_relay: true) }

  before(:all) { create_users }

  before(:each) do
    @authable = facility
    @params = { id: instrument.url_name, facility_id: facility.url_name }
    create(:instrument_price_policy, product: instrument, price_group: @nupg)
  end

  it "should route" do
    expect(get: "/#{I18n.t('facilities_downcase')}/alpha/instruments").to route_to(controller: "instruments", action: "index", facility_id: "alpha")
    expect(get: "/#{I18n.t('facilities_downcase')}/alpha/instruments/1/manage").to route_to(controller: "instruments", action: "manage", id: "1", facility_id: "alpha")
  end

  context "index" do
    before :each do
      @method = :get
      @action = :index
      @params.delete(:id)
    end

    it_should_allow_operators_only do |_user|
      expect(assigns(:products)).to eq([instrument])
      expect(response).to render_template("admin/products/index")
    end
  end

  describe "public_schedule" do
    before :each do
      @method = :get
      @action = :public_schedule
      @params[:instrument_id] = @params.delete(:id)
    end

    it "should not require login" do
      do_request
      expect(response).to be_successful
    end

    it "should set the instrument" do
      do_request
      expect(assigns[:product]).to eq(instrument)
    end

    it "should not have html tags in title" do
      do_request
      expect(response.body).to match("<title>[^<>]+</title>")
    end
  end

  context "manage" do
    before :each do
      @method = :get
      @action = :manage
    end

    it_should_allow_operators_only do |_user|
      expect(response).to render_template("manage")
    end
  end

  context "show" do
    before :each do
      @method = :get
      @action = :show
    end

    it_should_allow :guest, "but not add to cart" do
      expect(assigns[:product]).to eq(instrument)
      expect(assigns(:add_to_cart)).to be(false)
      expect(response).to render_template("show")
    end

    context "when it needs a valid account" do
      before :each do
        instrument.schedule_rules.create(attributes_for(:schedule_rule))
      end

      context "without a valid account" do
        before(:each) do
          maybe_grant_always_sign_in :director
          do_request
        end

        it "fails" do
          expect(response).to render_template("show")
          expect(assigns(:add_to_cart)).to be(false)
          expect(flash[:notice]).to be_present
        end
      end

      context "with a valid account" do
        before(:each) do
          add_account_for_user(:director, instrument)
          maybe_grant_always_sign_in :director
          do_request
        end

        it "succeeds" do
          expect(flash).to be_empty
          assert_redirected_to new_facility_instrument_single_reservation_path(facility, instrument)
        end
      end
    end

    context "when it lacks schedule rules" do
      before :each do
        facility_operators.each do |operator|
          add_account_for_user(operator, instrument)
        end
      end

      it "requires sign in" do
        do_request
        expect(assigns(:product)).to eq(instrument)
        assert_redirected_to new_user_session_path
      end

      it_should_allow_all(facility_operators) do
        expect(response).to render_template("show")
        expect(assigns(:add_to_cart)).to be(false)
        expect(flash[:notice]).to include("schedule for this instrument")
      end
    end

    context "when the instrument requires approval" do
      before :each do
        instrument.schedule_rules.create(attributes_for(:schedule_rule))
        instrument.update(requires_approval: true)
      end

      context "if the user is not approved" do
        before(:each) do
          sign_in @guest
          do_request
        end

        context "if the training request feature is enabled", feature_setting: { training_requests: true, reload_routes: true } do
          it "gives the user the option to submit a request for approval" do
            expect(assigns[:add_to_cart]).to be_blank
            assert_redirected_to(new_facility_product_training_request_path(facility, instrument))
          end
        end

        context "if the training request feature is disabled", feature_setting: { training_requests: false, reload_routes: true } do
          it "denies access to the user" do
            expect(assigns[:add_to_cart]).to be_blank
            expect(flash[:notice]).to include("instrument requires approval")
          end
        end
      end

      context "if the user is approved" do
        before(:each) do
          @product_user = ProductUser.create(
            product: instrument,
            user: @guest,
            approved_by: @admin.id,
            approved_at: Time.zone.now,
          )
          add_account_for_user(:guest, instrument)
          sign_in @guest
          do_request
        end

        it "adds the instrument to the cart" do
          expect(flash).to be_empty
          expect(assigns[:add_to_cart]).to be true
        end
      end

      context "if the user is an admin" do
        before(:each) do
          add_account_for_user(:admin, instrument)
          sign_in @admin
          do_request
        end

        it "adds the instrument to the cart" do
          expect(assigns[:add_to_cart]).to be true
        end
      end
    end

    context "when the instrument is hidden" do
      before do
        create(:schedule_rule, product: instrument)
        instrument.update!(is_hidden: true)
        facility_operators.each do |operator|
          add_account_for_user(operator, instrument)
        end
      end

      it_should_allow_operators_only(:redirect, "", false) do
        expect(assigns[:add_to_cart]).to be(true)
      end

      context "if acting as a user" do
        before(:each) do
          allow_any_instance_of(Instrument).to receive(:can_purchase?).and_return(true)
          add_account_for_user(:guest, instrument)
          sign_in @admin
          switch_to @guest
          do_request
        end

        it "adds to cart and redirects" do
          expect(assigns[:product]).to eq(instrument)
          expect(assigns[:add_to_cart]).to be true
          expect(response).to be_redirect
        end
      end
    end
  end

  context "new" do
    before :each do
      @method = :get
      @action = :new
    end

    it_should_allow_managers_only do
      expect(assigns(:product)).to be_kind_of Instrument
      expect(assigns(:product)).to be_new_record
      expect(assigns(:product).facility).to eq(facility)
      is_expected.to render_template "new"
    end
  end

  context "edit" do
    before :each do
      @method = :get
      @action = :edit
    end

    it_should_allow_managers_only do
      is_expected.to render_template "edit"
    end
  end

  context "create" do
    before :each do
      @method = :post
      @action = :create
      @params.merge!(
        instrument: attributes_for(:instrument,
                                   no_relay: true,
                                   facility_account_id: facility.facility_accounts.first.id,
                                  ),
      )
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Instrument
      expect(assigns(:product).initial_order_status_id).to eq(OrderStatus.default_order_status.id)

      expect(assigns(:product).relay).to be_nil

      is_expected.to set_flash
      assert_redirected_to manage_facility_instrument_url(facility, assigns(:product))
    end

    describe "shared schedule" do
      before :each do
        @schedule = create(:schedule, facility:)
        sign_in @admin
      end

      context "when wanting a new schedule" do
        before :each do
          @params[:instrument][:schedule_id] = ""
        end

        it "should create a new schedule" do
          expect { do_request }.to change { Schedule.count }.by(1)
        end

        it "should be the newest schedule" do
          do_request
          expect(assigns(:product).schedule).to eq(Schedule.last)
        end
      end

      context "when selecting an existing schedule" do
        before :each do
          @params[:instrument][:schedule_id] = @schedule.id.to_s
        end

        it "should use the existing schedule" do
          do_request
          expect(assigns(:product).schedule).to eq(@schedule)
        end
      end
    end

    context "fail" do
      before :each do
        @params[:instrument].delete(:name)
      end

      it_should_allow :director, "and fail when no name is given" do
        expect(assigns(:product)).to be_kind_of Instrument
        expect(assigns(:product).initial_order_status_id).to eq(OrderStatus.default_order_status.id)
        is_expected.to render_template "new"
      end
    end

    describe "daily booking permissions" do
      before do
        @params[:instrument] = attributes_for(
          :instrument,
          pricing_mode: Instrument::Pricing::SCHEDULE_DAILY,
          facility_account_id: facility.facility_accounts.first.id,
        )
      end

      shared_examples "daily booking creation disallowed" do
        it "does not allow user to create daily booking instrument" do
          sign_in(user)

          expect { do_request }.to_not change { Instrument.count }
          expect(@response.body).to(
            include(I18n.t("controllers.instruments.create.daily_booking_not_authorized"))
          )
        end
      end

      context "as facility admin" do
        let(:user) { create(:user, :facility_administrator, facility:) }

        include_examples "daily booking creation disallowed"
      end

      context "as facility director" do
        let(:user) { create(:user, :facility_director, facility:) }

        include_examples "daily booking creation disallowed"
      end

      context "as administrator" do
        let(:user) { create(:user, :administrator) }

        it "allows to create a daily booking instrument" do
          sign_in user

          expect { do_request }.to change { Instrument.count }.by(1)
        end
      end
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
    end

    def assert_successful_update
      expect(assigns(:product)).to eq(instrument)
      yield
      is_expected.to set_flash
      assert_redirected_to manage_facility_instrument_url(facility, assigns(:product))
    end
  end

  context "destroy" do
    before :each do
      @method = :delete
      @action = :destroy
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:product)).to be_kind_of Instrument
      assert_redirected_to facility_instruments_url
      dead = false

      begin
        Instrument.find(assigns(:product).id)
      rescue
        dead = true
      end

      assert dead
    end
  end

  context "instrument id" do
    before :each do
      @params[:instrument_id] = @params[:id]
      @params.delete(:id)
    end

    context "schedule" do
      before :each do
        @method = :get
        @action = :schedule
      end

      describe "schedule sharing" do
        let(:admin_reservation) do
          create(
            :admin_reservation,
            product: instrument,
            reserve_start_at: 2.days.from_now,
          )
        end
        let(:admin_reservation2) do
          create(
            :admin_reservation,
            product: instrument,
            reserve_start_at: 1.day.from_now,
          )
        end
        before :each do
          sign_in @admin
          do_request
        end

        it "should show the primary instrument's reservations" do
          expect(assigns(:admin_reservations)).to eq([admin_reservation2, admin_reservation])
        end

        it "should_allow_operators_only" do
          is_expected.to render_template "schedule"
        end
      end
    end

    context "instrument_statuses" do
      before :each do
        @method = :get
        @action = :instrument_statuses
        @instrument_with_relay = create(:instrument,
                                        facility:,
                                        no_relay: true)
        create(:relay_syna, instrument: @instrument_with_relay)
      end

      it_should_allow_operators_only {}

      context "signed in" do
        before :each do
          maybe_grant_always_sign_in :director
          do_request
          @json_output = JSON.parse(response.body, symbolize_names: true)
        end

        it "renders the expected attributes" do
          expect(@json_output.first).to match(
            instrument_status: a_hash_including(
              instrument_id: @instrument_with_relay.id,
              name: @instrument_with_relay.name,
            )
          )
        end
      end
    end

    context "switch" do
      before :each do
        @method = :get
        @action = :switch
        @params.merge!(switch: "on")
      end

      it_should_allow_operators_only

      context "signed in" do
        let(:instrument_with_relay) { create(:instrument, facility:, no_relay: true) }
        let!(:relay) { create(:relay_syna, instrument: instrument_with_relay) }

        before do
          @params[:instrument_id] = instrument_with_relay.url_name
          allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
          allow_any_instance_of(RelaySynaccessRevA).to receive(:toggle).and_return(true)
          maybe_grant_always_sign_in :director
        end

        it "creates a status if one does not exist" do
          expect do
            do_request
          end.to change(InstrumentStatus, :count).by(1)
        end

        it "updates an existing status instead of creating a new one" do
          InstrumentStatus.set_status_for(instrument_with_relay, is_on: false)
          expect(InstrumentStatus.where(instrument: instrument_with_relay).count).to eq(1)

          expect do
            do_request
          end.not_to change(InstrumentStatus, :count)

          expect(instrument_with_relay.reload.instrument_status).to be_on
        end

        it "returns the status as JSON" do
          do_request
          json = JSON.parse(response.body, symbolize_names: true)

          expect(json[:instrument_status][:is_on]).to be(true)
          expect(json[:instrument_status][:instrument_id]).to eq(instrument_with_relay.id)
        end
      end
    end

    context "instrument_statuses with refresh" do
      let(:instrument_with_relay) { create(:instrument, facility:, no_relay: true) }
      let!(:relay) { create(:relay_syna, instrument: instrument_with_relay) }

      before :each do
        @method = :get
        @action = :instrument_statuses
        @params.delete(:id)
      end

      context "with refresh=true" do
        before do
          @params[:refresh] = "true"
          allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
          allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)
          maybe_grant_always_sign_in :director
        end

        it "polls the relay and returns status" do
          expect_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(true)

          do_request
          json = JSON.parse(response.body, symbolize_names: true)

          status = json.find { |s| s[:instrument_status][:instrument_id] == instrument_with_relay.id }
          expect(status[:instrument_status][:is_on]).to be(true)
        end

        it "saves the status to the database" do
          expect do
            do_request
          end.to change(InstrumentStatus, :count).by(1)

          expect(instrument_with_relay.instrument_status).to be_on
        end

        context "with instrument_ids filter" do
          before do
            @params[:instrument_ids] = [instrument_with_relay.id]
          end

          it "only refreshes specified instruments" do
            do_request
            json = JSON.parse(response.body, symbolize_names: true)

            expect(json.length).to eq(1)
            expect(json.first[:instrument_status][:instrument_id]).to eq(instrument_with_relay.id)
          end
        end
      end
    end
  end
end
