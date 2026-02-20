# frozen_string_literal: true

require "rails_helper"
require "controller_spec_helper"

RSpec.describe ApplicationHelper do
  describe "#can_create_users?" do
    let(:current_ability) { Ability.new(user, current_facility, stub_controller) }
    let(:current_facility) { build_stubbed(:facility) }
    let(:stub_controller) { OpenStruct.new }
    let(:user) { build_stubbed(:user) }

    before(:each) do
      allow(current_ability)
        .to receive(:can?)
        .with(:create, User)
        .and_return(can_manage_users?)
    end

    context "when the user can :manage_users for the current facility" do
      let(:can_manage_users?) { true }

      context "and the :create_users feature is on", feature_setting: { create_users: true } do
        it { expect(can_create_users?).to be true }
      end

      context "and the :create_users feature is off", feature_setting: { create_users: false } do
        it { expect(can_create_users?).to be false }
      end
    end

    context "when the user cannot :manage_users for the current facility" do
      let(:can_manage_users?) { false }

      context "and the :create_users feature is on", feature_setting: { create_users: true } do
        it { expect(can_create_users?).to be false }
      end

      context "and the :create_users feature is off", feature_setting: { create_users: false } do
        it { expect(can_create_users?).to be false }
      end
    end
  end

  describe "#menu_facilities" do
    before(:all) do
      create_users
    end

    before(:each) do
      UserRole.grant(user, UserRole::FACILITY_DIRECTOR, facilities.first)
      UserRole.grant(user, UserRole::FACILITY_STAFF, facilities.second)
    end

    let!(:facilities) { create_list(:facility, 3) }

    def session_user
      user
    end

    shared_examples_for "it returns only facilities with a role" do
      it { expect(menu_facilities).to match_array(facilities.first(2)) }
    end

    context "when the user is a guest" do
      let(:user) { @guest }
      it_behaves_like "it returns only facilities with a role"
    end

    context "when the user is a global admin" do
      let(:user) { @admin }

      it "returns all facilities" do
        expect(menu_facilities).to match_array(facilities)
      end
    end

    context "when the user is a global billing_admin", feature_setting: { global_billing_administrator: true } do
      let(:user) { create(:user, :global_billing_administrator) }
      it_behaves_like "it returns only facilities with a role"
    end
  end
end
