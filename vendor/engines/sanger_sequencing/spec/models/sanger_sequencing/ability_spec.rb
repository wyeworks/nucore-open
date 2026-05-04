# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Ability do
  subject(:ability) { described_class.new(user, facility) }

  let(:facility) { create(:facility, sanger_sequencing_enabled: true) }

  describe "no user" do
    let(:user) { nil }

    it_is_not_allowed_to([:index, :show, :create, :update], SangerSequencing::Submission)
    it_is_not_allowed_to(:manage, SangerSequencing::Batch)
  end

  describe "submission owner" do
    let(:user) { create(:user) }
    let(:submission) { SangerSequencing::Submission.new }

    before { allow(submission).to receive(:user).and_return(user) }

    it { is_expected.to be_allowed_to(:show, submission) }
    it { is_expected.to be_allowed_to(:update, submission) }
    it { is_expected.to be_allowed_to(:create_sample, submission) }
  end

  describe "another user's submission" do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:submission) { SangerSequencing::Submission.new }

    before { allow(submission).to receive(:user).and_return(other_user) }

    it { is_expected.not_to be_allowed_to(:show, submission) }
    it { is_expected.not_to be_allowed_to(:update, submission) }
  end

  describe "facility staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it_is_allowed_to([:index, :show], SangerSequencing::Submission)
    it_is_allowed_to(:manage, SangerSequencing::Batch)
    it_is_allowed_to(:manage, SangerSequencing::BatchForm)
    it_is_allowed_to(:manage, SangerSequencing::Primer)
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it_is_allowed_to([:index, :show], SangerSequencing::Submission)
    it_is_allowed_to(:manage, SangerSequencing::Batch)
  end

  describe "global administrator" do
    let(:user) { create(:user, :administrator) }

    it_is_allowed_to([:index, :show], SangerSequencing::Submission)
    it_is_allowed_to(:manage, SangerSequencing::Batch)
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it_is_not_allowed_to([:index], SangerSequencing::Submission)
    it_is_not_allowed_to(:manage, SangerSequencing::Batch)
  end

  describe "user with granular permissions", feature_setting: { granular_permissions: true } do
    let(:user) { create(:user) }

    context "with product_management" do
      before do
        create(:facility_user_permission, user:, facility:, product_management: true)
      end

      it_is_allowed_to([:index, :show], SangerSequencing::Submission)
      it_is_allowed_to(:manage, SangerSequencing::Batch)
      it_is_allowed_to(:manage, SangerSequencing::BatchForm)
      it_is_allowed_to(:manage, SangerSequencing::Primer)
    end

    context "with read_access only (no product_management)" do
      before do
        create(:facility_user_permission, user:, facility:, read_access: true)
      end

      it_is_not_allowed_to([:index], SangerSequencing::Submission)
      it_is_not_allowed_to(:manage, SangerSequencing::Batch)
    end

    context "with product_management but read_access disabled" do
      before do
        permission = build(:facility_user_permission, user:, facility:, product_management: true, read_access: false)
        permission.save(validate: false)
      end

      it_is_not_allowed_to([:index], SangerSequencing::Submission)
      it_is_not_allowed_to(:manage, SangerSequencing::Batch)
    end

    context "with other granular permissions but not product_management" do
      before do
        create(:facility_user_permission, user:, facility:, order_management: true)
      end

      it_is_not_allowed_to([:index], SangerSequencing::Submission)
      it_is_not_allowed_to(:manage, SangerSequencing::Batch)
    end

    context "with permission for a different facility" do
      let(:other_facility) { create(:facility, sanger_sequencing_enabled: true) }

      before do
        create(:facility_user_permission, user:, facility: other_facility, product_management: true)
      end

      it_is_not_allowed_to([:index], SangerSequencing::Submission)
      it_is_not_allowed_to(:manage, SangerSequencing::Batch)
    end
  end

  describe "user with product_management granular permission, feature flag off",
           feature_setting: { granular_permissions: false } do
    let(:user) { create(:user) }

    before do
      create(:facility_user_permission, user:, facility:, product_management: true)
    end

    it_is_not_allowed_to([:index], SangerSequencing::Submission)
    it_is_not_allowed_to(:manage, SangerSequencing::Batch)
  end
end
