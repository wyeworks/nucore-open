# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe InstrumentsController do
  render_views

  let(:facility) { FactoryBot.create(:setup_facility) }
  let(:instrument) { FactoryBot.create(:instrument, facility: facility, no_relay: true) }

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
          assert_redirected_to(
            add_order_path(
              Order.all.last,
              order: { order_details: [product_id: instrument.id, quantity: 1] },
            ),
          )
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
        instrument.update_attributes(requires_approval: true)
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
        FactoryBot.create(:schedule_rule, product: instrument)
        instrument.update!(is_hidden: true)
        facility_operators.each do |operator|
          add_account_for_user(operator, instrument)
        end
      end

      it_should_allow_operators_only(:redirect) do
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
        instrument: FactoryBot.attributes_for(:instrument,
                                              facility_account_id: facility.facility_accounts.first.id,
                                              control_mechanism: "manual",
                                             ),
      )
    end

    it_should_allow_managers_only :redirect do
      assert_successful_creation { expect(assigns(:product).relay).to be_nil }
    end

    context "with relay" do

      before :each do
        @params[:instrument].merge!(control_mechanism: "relay",
                                    relay_attributes: {
                                      ip: "192.168.1.2",
                                      outlet: 12,
                                      username: "username",
                                      password: "password",
                                      type: RelaySynaccessRevA.name,
                                      auto_logout: true,
                                      auto_logout_minutes: 15,
                                    })
      end

      it_should_allow :director, "to create a relay" do
        assert_successful_creation do
          relay = assigns(:product).relay
          expect(relay).to be_is_a Relay
          expect(relay.ip).to eq(@params[:instrument][:relay_attributes][:ip])
          expect(relay.outlet).to eq(@params[:instrument][:relay_attributes][:outlet])
          expect(relay.username).to eq(@params[:instrument][:relay_attributes][:username])
          expect(relay.password).to eq(@params[:instrument][:relay_attributes][:password])
          expect(relay.type).to eq(@params[:instrument][:relay_attributes][:type])
          expect(relay.auto_logout_minutes).to eq(@params[:instrument][:relay_attributes][:auto_logout_minutes])
        end
      end

      describe "relay validations" do
        let!(:instrument2) { create(:instrument, facility: facility, no_relay: true) }
        let!(:old_relay) { create(:relay_syna, instrument: instrument2) }

        before :each do
          sign_in @admin
          @params[:instrument][:relay_attributes][:ip] = old_relay.ip
          @params[:instrument][:relay_attributes][:outlet] = old_relay.outlet
        end

        context "and the relay is taken by a different instrument" do
          it "does not allow the relay to be used again" do
            do_request
            expect(assigns(:product)).to_not be_persisted
            expect(assigns(:product).errors).to include(:relay)
          end
        end

        context "and the relay is taken, but on the same shared schedule" do
          it "allows creation" do
            @params[:instrument][:schedule_id] = instrument2.schedule_id
            do_request
            expect(assigns(:product)).to be_persisted
            expect(assigns(:product).relay).to be_persisted
          end
        end
      end

    end

    context "dummy relay" do

      before :each do
        # relay attributes
        @params[:instrument].merge!(control_mechanism: "timer")
      end

      it_should_allow :director, "to create a timer" do
        assert_successful_creation do
          relay = assigns(:product).relay
          expect(relay).to be_a Relay
          expect(relay.type).to eq(RelayDummy.name)
        end
      end
    end

    describe "shared schedule" do
      before :each do
        @schedule = FactoryBot.create(:schedule, facility: facility)
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

    def assert_successful_creation
      expect(assigns(:product)).to be_kind_of Instrument
      expect(assigns(:product).initial_order_status_id).to eq(OrderStatus.default_order_status.id)
      yield
      is_expected.to set_flash
      assert_redirected_to manage_facility_instrument_url(facility, assigns(:product))
    end
  end

  context "update" do
    before :each do
      @method = :put
      @action = :update
      @params.merge!(instrument: instrument.attributes.merge!(control_mechanism: "manual"))
    end

    context "no relay" do
      before :each do
        RelaySynaccessRevA.create!(
          ip: "192.168.1.2",
          outlet: 12,
          username: "username",
          password: "password",
          type: RelaySynaccessRevA.name,
          instrument_id: instrument.id,
        )
      end

      it_should_allow_managers_only :redirect do
        assert_successful_update { expect(assigns(:product).reload.relay).to be_nil }
      end
    end

    context "with relay" do

      before :each do
        @params[:instrument].merge!(control_mechanism: "relay",
                                    relay_attributes: {
                                      ip: "192.168.1.2",
                                      outlet: 12,
                                      username: "username",
                                      password: "password",
                                      type: RelaySynaccessRevA.name,
                                      instrument_id: instrument.id,
                                    })
      end

      it_should_allow :director, "to create a relay" do
        assert_successful_update do
          relay = assigns(:product).relay
          expect(relay).to be_is_a Relay
          expect(relay.ip).to eq(@params[:instrument][:relay_attributes][:ip])
          expect(relay.outlet).to eq(@params[:instrument][:relay_attributes][:outlet])
          expect(relay.username).to eq(@params[:instrument][:relay_attributes][:username])
          expect(relay.password).to eq(@params[:instrument][:relay_attributes][:password])
          expect(relay.type).to eq(@params[:instrument][:relay_attributes][:type])
        end
      end

    end

    context "dummy relay" do

      before :each do
        @params[:instrument].merge!(control_mechanism: "timer")
      end

      it_should_allow :director, "to create a timer" do
        assert_successful_update do
          relay = assigns(:product).relay
          expect(relay).to be_is_a Relay
          expect(relay.ip).to be_nil
          expect(relay.outlet).to be_nil
          expect(relay.username).to be_nil
          expect(relay.password).to be_nil
          expect(relay.type).to eq(RelayDummy.name)
        end
      end
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
          FactoryBot.create(
            :admin_reservation,
            product: instrument,
            reserve_start_at: 2.days.from_now,
          )
        end
        let(:admin_reservation2) do
          FactoryBot.create(
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

    context "instrument statuses" do
      before :each do
        # So it doesn't try to actually connect
        allow(SettingsHelper).to receive(:relays_enabled_for_admin?).and_return(true)
        allow_any_instance_of(RelaySynaccessRevA).to receive(:query_status).and_return(false)

        @method = :get
        @action = :instrument_statuses
        @instrument_with_relay = FactoryBot.create(:instrument,
                                                   facility: facility,
                                                   no_relay: true)
        FactoryBot.create(:relay_syna, instrument: @instrument_with_relay)

        @instrument_with_dummy_relay = FactoryBot.create(:instrument,
                                                         facility: facility,
                                                         no_relay: true)
        FactoryBot.create(:relay_dummy, instrument: @instrument_with_dummy_relay)

        @instrument_with_dummy_relay.instrument_statuses.create(is_on: true)
        @instrument_with_bad_relay = FactoryBot.create(:instrument,
                                                       facility: facility,
                                                       no_relay: true)

        FactoryBot.create(:relay_synb, instrument: @instrument_with_bad_relay)
        allow_any_instance_of(RelaySynaccessRevB).to receive(:query_status).and_raise(StandardError.new("Error!"))
        @instrument_with_bad_relay.relay.update_attribute(:ip, "")
      end

      it_should_allow_operators_only {}

      context "signed in" do
        before :each do
          maybe_grant_always_sign_in :director
          do_request
          @json_output = JSON.parse(response.body, symbolize_names: true)
          @instrument_ids = @json_output.map { |hash| hash[:instrument_status][:instrument_id] }
        end

        it "should not return instruments without relays" do
          expect(assigns[:instrument_statuses].map(&:instrument)).not_to be_include @instrument
          expect(@instrument_ids).not_to be_include instrument.id
        end
        it "should include instruments with real relays" do
          expect(assigns[:instrument_statuses].map(&:instrument)).to be_include @instrument_with_relay
          expect(@instrument_ids).to be_include @instrument_with_relay.id
        end
        it "should include instruments with dummy relays" do
          expect(assigns[:instrument_statuses].map(&:instrument)).to be_include @instrument_with_dummy_relay
          expect(@instrument_ids).to be_include @instrument_with_dummy_relay.id
        end

        it "should return an error if the relay is missing a host" do
          expect(assigns[:instrument_statuses].last.instrument).to eq(@instrument_with_bad_relay)
          expect(assigns[:instrument_statuses].last.error_message).not_to be_nil
        end

        it "should return true for a relay thats switched on" do
          expect(assigns[:instrument_statuses][1].instrument).to eq(@instrument_with_dummy_relay)
          expect(assigns[:instrument_statuses][1].is_on).to be true
          expect(@json_output[1][:instrument_status][:instrument_id]).to eq(@instrument_with_dummy_relay.id)
          expect(@json_output[1][:instrument_status][:is_on]).to be true
        end
        it "should return false for a relay thats not turned on" do
          expect(assigns[:instrument_statuses].first.instrument).to eq(@instrument_with_relay)
          expect(assigns[:instrument_statuses].first.is_on).to be false
          expect(@json_output[0][:instrument_status][:is_on]).to be false
          expect(@json_output[0][:instrument_status][:instrument_id]).to eq(@instrument_with_relay.id)
        end

        it "should create a new false instrument status if theres nothing" do
          expect(@instrument_with_relay.reload.instrument_statuses.size).to eq(1)
        end
        it "should not create a second true instrument status" do
          expect(@instrument_with_dummy_relay.reload.instrument_statuses.size).to eq(1)
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

    end
  end
end
