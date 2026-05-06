# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::LinkCollectionExtension do
  subject(:link) { NavTab::LinkCollection.new(facility, ability, user).admin_sanger_sequencing }

  let(:facility) { create(:facility, sanger_sequencing_enabled: true) }
  let(:ability) { Ability.new(user, facility) }

  describe "facility staff" do
    let(:user) { create(:user, :staff, facility: facility) }

    it { is_expected.to be_a(NavTab::Link) }
  end

  describe "facility administrator" do
    let(:user) { create(:user, :facility_administrator, facility: facility) }

    it { is_expected.to be_a(NavTab::Link) }
  end

  describe "global administrator" do
    let(:user) { create(:user, :administrator) }

    it { is_expected.to be_a(NavTab::Link) }
  end

  describe "unprivileged user" do
    let(:user) { create(:user) }

    it { is_expected.to be_nil }
  end

  describe "user with granular permissions", feature_setting: { granular_permissions: true } do
    let(:user) { create(:user) }

    context "with product_management" do
      before { create(:facility_user_permission, user:, facility:, product_management: true) }

      it { is_expected.to be_a(NavTab::Link) }
    end

    context "with read_access only" do
      before { create(:facility_user_permission, user:, facility:, read_access: true) }

      it { is_expected.to be_nil }
    end

    context "with order_management but no product_management" do
      before { create(:facility_user_permission, user:, facility:, order_management: true) }

      it { is_expected.to be_nil }
    end
  end

  describe "facility without sanger_sequencing_enabled" do
    let(:facility) { create(:facility, sanger_sequencing_enabled: false) }
    let(:user) { create(:user, :administrator) }

    it { is_expected.to be_nil }
  end
end
