# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::AbilityExtension do
  let(:facility) { project.facility }
  let(:project) { FactoryBot.build(:project) }
  let(:stub_controller) { OpenStruct.new }

  describe "facility level actions" do
    let(:common_actions_on_facility_level) { %i(create edit index new update) }
    subject(:ability) { Ability.new(user, facility, stub_controller) }

    shared_examples_for "it has full access for facility level actions" do
      it "has full access" do
        common_actions_on_facility_level.each do |action|
          is_expected.to be_allowed_to(action, Projects::Project)
        end
      end
    end

    shared_examples_for "it has no access for facility level actions" do
      it "has no access" do
        common_actions_on_facility_level.each do |action|
          is_expected.not_to be_allowed_to(action, Projects::Project)
        end
      end
    end

    describe "account manager" do
      let(:user) { FactoryBot.create(:user, :account_manager) }
      it_behaves_like "it has no access for facility level actions"
    end

    describe "administrator" do
      let(:user) { FactoryBot.create(:user, :administrator) }
      it_behaves_like "it has full access for facility level actions"
    end

    describe "global billing administrator", feature_setting: { global_billing_administrator: true } do
      let(:user) { FactoryBot.create(:user, :global_billing_administrator) }
      it_behaves_like "it has no access for facility level actions"
    end

    describe "facility administrator" do
      let(:user) { FactoryBot.create(:user, :facility_administrator, facility:) }
      it_behaves_like "it has full access for facility level actions"
    end

    describe "facility director" do
      let(:user) { FactoryBot.create(:user, :facility_director, facility:) }
      it_behaves_like "it has full access for facility level actions"
    end

    describe "facility billing administrator" do
      let(:user) { FactoryBot.create(:user, :facility_billing_administrator, facility:) }
      it_behaves_like "it has no access for facility level actions"
    end

    describe "senior staff" do
      let(:user) { FactoryBot.create(:user, :senior_staff, facility:) }
      it_behaves_like "it has full access for facility level actions"
    end

    describe "staff" do
      let(:user) { FactoryBot.create(:user, :staff, facility:) }
      it_behaves_like "it has full access for facility level actions"
    end

    describe "unprivileged user" do
      let(:user) { FactoryBot.create(:user) }
      it_behaves_like "it has no access for facility level actions"
    end
  end

  describe "project level actions" do
    let(:common_actions_on_project_level) { %i(show) }
    subject(:ability) { Ability.new(user, project, stub_controller) }

    shared_examples_for "it has full access for project level actions" do
      # They *could* have access to *a* project, but not necessarily *all* projects.
      it "has full access" do
        common_actions_on_project_level.each do |action|
          is_expected.to be_allowed_to(action, Projects::Project)
        end
      end
    end

    shared_examples_for "it has no access for project level actions" do
      it "has no access" do
        common_actions_on_project_level.each do |action|
          is_expected.not_to be_allowed_to(action, Projects::Project)
        end
      end
    end

    describe "account manager" do
      let(:user) { FactoryBot.create(:user, :account_manager) }
      it_behaves_like "it has no access for project level actions"
    end

    describe "administrator" do
      let(:user) { FactoryBot.create(:user, :administrator) }
      it_behaves_like "it has full access for project level actions"
    end

    describe "global billing administrator", feature_setting: { global_billing_administrator: true } do
      let(:user) { FactoryBot.create(:user, :global_billing_administrator) }
      it_behaves_like "it has no access for project level actions"
    end

    describe "facility administrator" do
      let(:user) { FactoryBot.create(:user, :facility_administrator, facility:) }
      it_behaves_like "it has full access for project level actions"
    end

    describe "facility director" do
      let(:user) { FactoryBot.create(:user, :facility_director, facility:) }
      it_behaves_like "it has full access for project level actions"
    end

    describe "facility billing administrator" do
      let(:user) { FactoryBot.create(:user, :facility_billing_administrator, facility:) }
      it_behaves_like "it has no access for project level actions"
    end

    describe "senior staff" do
      let(:user) { FactoryBot.create(:user, :senior_staff, facility:) }
      it_behaves_like "it has full access for project level actions"
    end

    describe "staff" do
      let(:user) { FactoryBot.create(:user, :staff, facility:) }
      it_behaves_like "it has full access for project level actions"
    end

    describe "unprivileged user" do
      let(:user) { FactoryBot.create(:user) }
      it_behaves_like "it has no access for project level actions"
    end
  end
end
