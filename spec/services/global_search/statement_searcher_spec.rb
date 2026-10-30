# frozen_string_literal: true

require "rails_helper"

RSpec.describe GlobalSearch::StatementSearcher do
  describe "#results" do
    subject(:results) { described_class.new(user, facility, query).results }

    let(:creator) { FactoryBot.create(:user) }
    let(:facility) { nil }
    let!(:statement) { FactoryBot.create(:statement, created_by_user: creator) }

    describe "as a global admin" do
      let(:user) { FactoryBot.create(:user, :administrator) }

      describe "with bad input" do
        let(:query) { "whatever" }
        it { is_expected.to be_empty }
      end

      describe "with nil input" do
        let(:query) { nil }
        it { is_expected.to be_empty }
      end

      describe "with blank input" do
        let(:query) { "" }
        it { is_expected.to be_empty }
      end

      describe "with the invoice number" do
        let(:query) { statement.invoice_number }
        it { is_expected.to eq([statement]) }
      end

      describe "with the id only" do
        let(:query) { statement.id }
        it { is_expected.to eq([statement]) }
      end

      describe "with the invoice number and whitespace" do
        let(:query) { "   #{statement.invoice_number}  " }
        it { is_expected.to eq([statement]) }
      end

      describe "with an non-existent statement" do
        let(:query) { "0-0" }
        it { is_expected.to be_empty }
      end

      describe "with the correct statement ID, but wrong account_id" do
        let(:query) { "0-#{statement.id}" }
        it { is_expected.to be_empty }
      end

      describe "starting with a pound sign" do
        let(:query) { "##{statement.invoice_number}" }
        it { is_expected.to eq([statement]) }
      end

      describe "id only starting with a pound sign" do
        let(:query) { "##{statement.id}" }
        it { is_expected.to eq([statement]) }
      end

      describe "with a pound sign and whitespace" do
        let(:query) { "  ##{statement.invoice_number}  " }
        it { is_expected.to eq([statement]) }
      end
    end

    describe "permissions" do
      let(:query) { statement.invoice_number }

      describe "as a random user" do
        let(:user) { FactoryBot.create(:user) }

        it { is_expected.to be_empty }
      end

      describe "facility roles" do
        describe "as a facility admin" do
          let(:user) { FactoryBot.create(:user, :facility_administrator, facility: statement.facility) }
          it { is_expected.to eq([statement]) }
        end

        describe "as a facility admin for another facility" do
          let(:other_facility) { FactoryBot.create(:facility) }
          let(:user) { FactoryBot.create(:user, :facility_administrator, facility: other_facility) }
          it { is_expected.to be_empty }
        end

        describe "as a facility director" do
          let(:user) { FactoryBot.create(:user, :facility_administrator, facility: statement.facility) }
          it { is_expected.to eq([statement]) }
        end

        describe "as a senior staff" do
          let(:user) { FactoryBot.create(:user, :senior_staff, facility: statement.facility) }
          it { is_expected.to be_empty }
        end

        describe "as a staff" do
          let(:user) { FactoryBot.create(:user, :staff, facility: statement.facility) }
          it { is_expected.to be_empty }
        end
      end

      describe "account roles" do
        let(:grantor) { FactoryBot.build_stubbed(:user) }

        describe "as the owner of the account" do
          let(:user) { statement.account.owner_user }
          it { is_expected.to eq([statement]) }
        end

        describe "as the purchaser on the account" do
          let(:user) { FactoryBot.create(:user, :purchaser, account: statement.account, administrator: grantor) }
          it { is_expected.to be_empty }
        end

        describe "as a business admin on the account" do
          let(:user) { FactoryBot.create(:user, :business_administrator, account: statement.account, administrator: grantor) }
          it { is_expected.to eq([statement]) }
        end
      end
    end
  end
end
