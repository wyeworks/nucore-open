require "rails_helper"

RSpec.describe UserPresenter do
  subject { described_class.new(user) }
  let(:global_role_list) { subject.global_role_list }
  let(:global_role_select_options) { subject.global_role_select_options }

  shared_examples_for "it has no global roles" do
    it { expect(global_role_list).to eq("") }
    it { expect(global_role_select_options).not_to include('selected="selected"') }
  end

  shared_examples_for "it has one global role" do
    it { expect(global_role_list).to eq("Administrator") }
    it { expect(global_role_select_options).to include('selected="selected">Administrator') }
    it { expect(global_role_select_options).not_to include('selected="selected">Billing Administrator') }
  end

  shared_examples_for "it has multiple global roles" do
    it { expect(global_role_list).to eq("Administrator, Billing Administrator") }
    it { expect(global_role_select_options).to include('selected="selected">Administrator') }
    it { expect(global_role_select_options).to include('selected="selected">Billing Administrator') }
  end

  context "when the user has no global roles" do
    let(:user) { create(:user) }

    it_behaves_like "it has no global roles"
  end

  context "when the user has one global role" do
    let(:user) { create(:user, :administrator) }

    it_behaves_like "it has one global role"
  end

  context "when the user has multiple global roles" do
    let(:user) { create(:user, :administrator, :billing_administrator) }

    it_behaves_like "it has multiple global roles"
  end

  describe "#name_last_comma_first" do
    let(:user) { create(:user, first_name: "First", last_name: "Last") }

    it { expect(subject.name_last_comma_first).to eq("Last, First") }
  end
end
