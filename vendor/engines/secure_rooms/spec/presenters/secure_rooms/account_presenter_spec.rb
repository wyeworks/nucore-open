# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecureRooms::AccountPresenter do
  let(:presenter_attributes) do
    %w[id type description account_number expiration_month expiration_year owner_name]
  end

  describe ".wrap" do
    let(:accounts) { build_stubbed_list :account, 3, :with_account_owner }
    subject(:presenters) { described_class.wrap(accounts) }

    it { is_expected.to all(be_a(described_class)) }

    describe "serialized list" do
      let(:json) { ActiveSupport::JSON.encode presenters }

      subject(:parsed_list) { JSON.parse(json) }

      it "contains correct number of accounts" do
        expect(parsed_list.length).to eq 3
      end

      describe "individual account json" do
        subject(:keys) { parsed_list.first.keys }

        it { is_expected.to eq presenter_attributes }
      end
    end
  end

  describe "instance methods" do
    let(:account) { create :account, :with_account_owner }
    subject(:presenter) { described_class.new(account) }

    describe "#to_json" do
      subject(:parsed_json) { JSON.parse(presenter.to_json) }

      describe "keys" do
        subject(:keys) { parsed_json.keys }

        it { is_expected.to eq presenter_attributes }
      end
    end
  end
end
