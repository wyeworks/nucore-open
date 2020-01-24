# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilitiesController do
  render_views

  it "routes", :aggregate_failures do
    expect(get: "/#{facilities_route}").to route_to(controller: "facilities", action: "index")
    expect(get: "/#{facilities_route}/url_name").to route_to(controller: "facilities", action: "show", id: "url_name")
    expect(get: "/#{facilities_route}/url_name/manage").to route_to(controller: "facilities", action: "manage", id: "url_name")
  end

  before(:all) { create_users }

  let(:facility) { FactoryBot.create(:facility) }
  let(:facility_account) { FactoryBot.create(:facility_account, facility: facility) }

  before(:each) do
    @authable = facility
  end

  context "new" do
    before(:each) do
      @method = :get
      @action = :new
    end

    it_should_require_login

    it_should_deny :director

    it_should_allow :admin do
      expect(@controller).to receive(:init_current_facility).never
      do_request
      expect(response).to be_successful.and render_template("facilities/new")
    end
  end

  context "create" do
    before(:each) do
      @method = :post
      @action = :create
      @params = {
        facility: {
          name: "A New Facility", abbreviation: "anf", description: "A boring description",
          is_active: 1, url_name: "anf", short_description: "A short boring desc",
          accepts_multi_add: true, show_instrument_availability: true,
          address: "Test Address", phone_number: "555-1223", fax_number: "555-3211",
          email: "facility@example.com"
        },
      }
    end

    it_should_require_login

    it_should_deny_all [:guest, :director]

    it_should_allow :admin do
      expect(facility).to be_valid
      expect(response).to redirect_to manage_facility_path("anf")
    end

    describe "as an admin" do
      before { sign_in @admin }

      it "sets all the fields", :aggregate_failures do
        do_request
        facility = assigns(:facility)

        expect(facility.name).to eq("A New Facility")
        expect(facility.abbreviation).to eq("anf")
        expect(facility.description).to eq("A boring description")
        expect(facility).to be_is_active
        expect(facility.url_name).to eq("anf")
        expect(facility.short_description).to eq("A short boring desc")
        expect(facility).to be_accepts_multi_add
        expect(facility).to be_show_instrument_availability
        expect(facility.address).to eq("Test Address")
        expect(facility.phone_number).to eq("555-1223")
        expect(facility.fax_number).to eq("555-3211")
        expect(facility.email).to eq("facility@example.com")
      end

      it "does not allow setting journal_mask" do
        @params[:facility][:journal_mask] = "C17"
        do_request
        expect(assigns(:facility).journal_mask).not_to eq("C17")
      end
    end
  end

  describe "PUT #update" do
    let(:facility) { FactoryBot.create(:facility) }
    before(:each) do
      @method = :put
      @action = :update
      @params = {
        id: facility.url_name,
        facility: {
          abbreviation: "anf",
          accepts_multi_add: false,
          address: "Test Address",
          description: "A boring description",
          email: "facility@example.com",
          fax_number: "555-3211",
          is_active: 0,
          name: "A New Facility",
          order_notification_recipient: "order@example.net",
          phone_number: "555-1223",
          short_description: "A short boring desc",
          show_instrument_availability: false,
          url_name: "anf",
        },
      }
    end

    it_should_require_login

    it_should_deny_all [:guest]

    describe "as an admin" do
      before { sign_in @admin }

      it "sets all the fields", :aggregate_failures do
        do_request
        facility.reload

        expect(facility.abbreviation).to eq("anf")
        expect(facility.address).to eq("Test Address")
        expect(facility.description).to eq("A boring description")
        expect(facility.email).to eq("facility@example.com")
        expect(facility.fax_number).to eq("555-3211")
        expect(facility.name).to eq("A New Facility")
        expect(facility.order_notification_recipient).to eq("order@example.net")
        expect(facility.phone_number).to eq("555-1223")
        expect(facility.short_description).to eq("A short boring desc")
        expect(facility.url_name).to eq("anf")

        expect(facility).not_to be_accepts_multi_add
        expect(facility).not_to be_is_active
        expect(facility).not_to be_show_instrument_availability
      end

      it "does not allow setting journal_mask" do
        @params[:facility][:journal_mask] = "C17"
        do_request
        expect(facility.reload.journal_mask).not_to eq("C17")
      end
    end
  end

  context "index" do
    before(:each) do
      @method = :get
      @action = :index
    end

    it "should render the page without a logged in user" do
      do_request
      expect(response).to be_successful
    end

    it_should_allow_all [:admin, :guest] do
      expect(assigns[:facilities]).to eq([@authable])
      expect(response).to be_successful.and render_template("facilities/index")
    end
  end

  context "manage" do
    before(:each) do
      @method = :get
      @action = :manage
      @params = { facility_id: @authable.url_name, id: @authable.url_name }
    end

    it_should_require_login

    it_should_deny :guest

    it_should_allow :director do
      expect(response).to be_successful.and render_template("facilities/manage")
    end
  end

  context "show" do
    before(:each) do
      @method = :get
      @action = :show
      @params = { id: facility.url_name }
    end

    it_should_allow_all ([:guest] + facility_operators) do
      expect(@controller.current_facility).to eq(facility)
      expect(response).to be_successful.and render_template("facilities/show")
    end

    describe "daily view link" do
      let!(:instrument) { create(:instrument, facility: facility, facility_account: facility_account) }

      it "includes link to daily view", feature_setting: { daily_view: true, reload_routes: true } do
        do_request
        expect(response.body).to include("daily view")
      end

      it "does not include a link to the daily view when disabled", feature_setting: { daily_view: false, reload_routes: true } do
        do_request
        expect(response.body).not_to include("daily view")
      end
    end

    context "when requesting the 'all' facility (cross-facility)" do
      let(:facility) { Facility.cross_facility }

      it "redirects to the index" do
        do_request
        expect(response).to redirect_to(facilities_path)
      end
    end

    it "should 404 for invalid facility" do
      @params[:id] = "randomstringofcharacters"
      do_request
      expect(response.code).to eq("404")
    end
  end

  context "list" do
    before(:each) do
      @method = :get
      @action = :list
    end

    it_should_require_login

    it_should_deny :guest

    context "as facility operators with two facilities" do
      before(:each) do
        @facility2 = FactoryBot.create(:facility)
        allow(@controller).to receive(:current_facility).and_return(@authable)
        allow(@controller).to receive(:operable_facilities).and_return([@authable, @facility2])
        expect(@controller).to receive(:init_current_facility).never
      end

      it_should_allow_all facility_operators do
        expect(assigns(:facilities)).to eq([@authable, @facility2])
        expect(response).to be_successful.and render_template("facilities/list")
      end
    end

    context "as facility operators with one facility" do
      before(:each) do
        allow(@controller).to receive(:current_facility).and_return(@authable)
        expect(@controller).to receive(:init_current_facility).never
      end
      context "has instruments" do
        before :each do
          FactoryBot.create(:instrument, facility: @authable, facility_account: facility_account)
        end
        it_should_allow_all (facility_operators - [:admin]) do
          expect(assigns(:facilities)).to eq([@authable])
          expect(assigns(:operable_facilities)).to eq([@authable])
          expect(response).to redirect_to(dashboard_facility_path(@authable))
        end
      end
      context "has no instruments" do
        # admin won't be redirected since their operable facilities is something more
        it_should_allow_all (facility_operators - [:admin]) do
          expect(assigns(:facilities)).to eq([@authable])
          expect(assigns(:operable_facilities)).to eq([@authable])
          expect(response).to redirect_to(dashboard_facility_path(@authable))
        end
      end
    end

    context "as administrator" do
      before(:each) do
        @facility2 = FactoryBot.create(:facility)
        allow(@controller).to receive(:current_facility).and_return(@authable)
      end

      it_should_allow :admin do
        expect(assigns[:facilities]).to eq([@authable, @facility2])
        expect(response).to be_successful.and render_template("facilities/list")
      end
    end
  end

  shared_context "transactions" do |action|
    before :each do
      @action = action
      @method = :get
      @params = { facility_id: @authable.url_name }
      @user = @admin
    end

    it_should_support_searching(:fulfilled_at)

    it "should use two column head" do
      sign_in @admin
      do_request
      expect(response).to render_template("two_column_head")
    end

    it "should query against the facility" do
      sign_in @admin
      do_request
      expect(assigns(:order_details)).to contain_string_in_sql "`orders`.`facility_id` = "
    end

    it_should_allow_managers_only
  end

end
