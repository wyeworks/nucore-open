# frozen_string_literal: true

require "rails_helper"

RSpec.describe Project, type: :model do
  subject(:project) { build(:project) }

  context "validations" do
    it { is_expected.to validate_presence_of(:facility_id) }
    it { is_expected.to belong_to(:facility).with_foreign_key(:facility_id) }
    it { is_expected.to have_many(:order_details).inverse_of(:project) }

    it "enforces unique names per facility" do
      is_expected
        .to validate_uniqueness_of(:name)
        .case_insensitive
        .scoped_to(:facility_id)
    end
  end

  context "when its facility is destroyed" do
    subject(:project) { create(:project) }

    before { project.facility.destroy }

    it "is destroyed" do
      pending "Facilities cannot be destroyed"
      is_expected.to be_destroyed
    end
  end

  describe "#total_cost" do
    before do
      project.order_details.build(estimated_cost: nil, estimated_subsidy: nil)
      project.order_details.build(estimated_cost: 1.5, estimated_subsidy: 0.25)
      project.order_details.build(estimated_cost: 2.3, estimated_subsidy: 0, actual_cost: 3.24, actual_subsidy: 0.03)
    end

    it "finds the total" do
      expect(project.total_cost).to eq(4.46)
    end
  end

  context "abilities" do
    let(:facility) { project.facility }
    let(:stub_controller) { OpenStruct.new }

    describe "facility level actions" do
      let(:common_actions_on_facility_level) { %i(create edit index new update) }
      subject(:ability) { Ability.new(user, facility, stub_controller) }

      shared_examples_for "it has full access for facility level actions" do
        it "has full access" do
          common_actions_on_facility_level.each do |action|
            is_expected.to be_allowed_to(action, Project)
          end
        end
      end

      shared_examples_for "it has no access for facility level actions" do
        it "has no access" do
          common_actions_on_facility_level.each do |action|
            is_expected.not_to be_allowed_to(action, Project)
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
            is_expected.to be_allowed_to(action, Project)
          end
        end
      end

      shared_examples_for "it has no access for project level actions" do
        it "has no access" do
          common_actions_on_project_level.each do |action|
            is_expected.not_to be_allowed_to(action, Project)
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
end
