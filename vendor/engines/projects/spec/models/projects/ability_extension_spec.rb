require "rails_helper"
require_relative "../../projects_spec_helper"

RSpec.describe Projects::AbilityExtension do
  subject(:ability) { Ability.new(user, facility, stub_controller) }
  let(:facility) { project.facility }
  let(:project) { FactoryGirl.build(:project) }
  let(:stub_controller) { OpenStruct.new }

  shared_examples_for "it has full access" do
    it "has full access" do
      is_expected.to be_allowed_to(:create, Projects::Project)
      is_expected.to be_allowed_to(:index, Projects::Project)
      is_expected.to be_allowed_to(:new, Projects::Project)
    end
  end

  shared_examples_for "it has no access" do
    it "has no access" do
      is_expected.not_to be_allowed_to(:create, Projects::Project)
      is_expected.not_to be_allowed_to(:index, Projects::Project)
      is_expected.not_to be_allowed_to(:new, Projects::Project)
    end
  end

  describe "account manager" do
    let(:user) { FactoryGirl.create(:user, :account_manager) }
    it_behaves_like "it has no access"
  end

  describe "administrator" do
    let(:user) { FactoryGirl.create(:user, :administrator) }
    it_behaves_like "it has full access"
  end

  describe "billing administrator", feature_setting: { billing_administrator: true } do
    let(:user) { FactoryGirl.create(:user, :billing_administrator) }
    it_behaves_like "it has no access"
  end

  describe "facility administrator" do
    let(:user) { FactoryGirl.create(:user, :facility_administrator, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "facility director" do
    let(:user) { FactoryGirl.create(:user, :facility_director, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "senior staff" do
    let(:user) { FactoryGirl.create(:user, :senior_staff, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "staff" do
    let(:user) { FactoryGirl.create(:user, :staff, facility: facility) }
    it_behaves_like "it has full access"
  end

  describe "unprivileged user" do
    let(:user) { FactoryGirl.create(:user) }
    it_behaves_like "it has no access"
  end
end
