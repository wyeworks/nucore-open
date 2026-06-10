# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserPresenter, feature_setting: { "roles.global_billing_administrator" => true } do
  subject { described_class.new(user) }
  let(:global_role_list) { subject.global_role_list }
  let(:global_role_select_options) { subject.global_role_select_options }

  context "when the user has no global roles" do
    let(:user) { create(:user) }

    it { expect(global_role_list).to eq("") }
    it { expect(global_role_select_options).not_to include('selected="selected"') }
  end

  context "when the user has one global role" do
    let(:user) { create(:user, :administrator) }

    describe "#global_role_list" do
      it { expect(global_role_list).to eq("Administrator") }
    end

    describe "#global_role_select_options" do
      it "returns appropriate <select> options", :aggregate_failures do
        expect(global_role_select_options)
          .to include('selected="selected" value="Administrator">Administrator')
        expect(global_role_select_options)
          .not_to include('selected="selected" value="Global Billing Administrator">Global Billing Administrator')
      end
    end
  end

  context "when the user has multiple global roles" do
    let(:user) { create(:user, :administrator, :global_billing_administrator) }

    describe "#global_role_list" do
      it { expect(global_role_list).to eq("Administrator, Global Billing Administrator") }
    end

    describe "#global_role_select_options" do
      it "returns appropriate <select> options", :aggregate_failures do
        expect(global_role_select_options)
          .to include('selected="selected" value="Administrator">Administrator')
        expect(global_role_select_options)
          .to include('selected="selected" value="Global Billing Administrator">Global Billing Administrator')
      end
    end
  end
end
