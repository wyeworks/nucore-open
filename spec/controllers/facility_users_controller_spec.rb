# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe FacilityUsersController do
  render_views

  before(:all) { create_users }

  let(:facility) { FactoryBot.create(:facility) }

  before(:each) do
    @authable = facility
    @params = { facility_id: @authable.url_name }
  end

  context "index" do

    before :each do
      @method = :get
      @action = :index
      grant_role(@staff)
    end

    it_should_allow_managers_only do |user|
      expect(assigns(:users).size).to be >= 1
      expect(assigns(:users)).to include @staff
      expect(assigns(:users)).to include user unless user == @admin
    end

  end

  context "destroy" do

    before :each do
      @method = :delete
      @action = :destroy
      grant_role(@staff)
      @params.merge!(id: @staff.id)
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      expect(assigns(:user)).to eq(@staff)
      expect(@staff.reload.facility_user_roles(@authable)).to be_empty
      assert_redirected_to facility_facility_users_url
    end

    it "logs events" do
      director = create(:user, :facility_director, facility: facility)
      sign_in director

      delete :destroy, params: { facility_id: facility.url_name, id: @staff.id }
      user_role = UserRole.deleted.find_by(user: @staff, facility: facility)
      expect(LogEvent).to be_exists(loggable: user_role, event_type: :delete, user: director)
    end

  end

  context "search" do

    before :each do
      @method = :get
      @action = :search
    end

    it_should_allow_managers_only { is_expected.to render_template("search") }

  end

  context "map_user" do

    before :each do
      @method = :post
      @action = :map_user
      @params.merge!(facility_user_id: @staff.id, user_role: { role: UserRole::FACILITY_STAFF })
    end

    it_should_allow_managers_only :redirect do
      expect(assigns(:user)).to be_kind_of User
      expect(assigns(:user)).to eq(@staff)
      expect(assigns(:user_role)).to be_kind_of UserRole
      expect(assigns(:user_role).user).to eq(@staff)
      expect(assigns(:user_role).facility).to eq(@authable)
      assert_redirected_to facility_facility_users_url
    end

    describe "as a director" do
      let(:director) { create(:user, :facility_director, facility: facility) }
      before { sign_in director }

      it "logs an event" do
        post :map_user, params: @params

        user_role = UserRole.find_by(user: @staff, facility: facility)
        expect(LogEvent).to be_exists(loggable: user_role, event_type: :create, user: director)
      end

      it "does not log an event if it's a duplicate role" do
        create(:user_role, :facility_staff, user: @staff, facility: facility)

        expect do
          post :map_user, params: @params
        end.not_to change(LogEvent, :count)
      end
    end

  end

end
