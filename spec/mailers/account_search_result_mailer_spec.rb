# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccountSearchResultMailer do
  let(:facility) { create(:facility) }
  let(:owner) { create(:user, first_name: "John", last_name: "Doe") }
  let!(:account1) { create(:nufs_account, :with_account_owner, owner:, account_number: "12345", description: "Account One") }
  let!(:account2) { create(:nufs_account, :with_account_owner, owner:, account_number: "67890", description: "Account Two") }
  let(:email) { "test@example.com" }

  describe "#search_result" do
    context "with a search term" do
      let(:mail) { described_class.search_result(email, "12345", facility).deliver_now }

      it "sends an email" do
        expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "has the correct recipient" do
        expect(mail.to).to eq([email])
      end

      it "has an attachment" do
        expect(mail.attachments.count).to eq(1)
        expect(mail.attachments.first.filename).to eq("accounts.csv")
      end

      it "includes matching accounts in the CSV" do
        csv_content = mail.attachments.first.body.to_s
        expect(csv_content).to include("12345")
        expect(csv_content).to include("Account One")
      end
    end

    context "with a blank search term" do
      let(:mail) { described_class.search_result(email, "", facility).deliver_now }

      it "sends an email" do
        expect { mail }.to change(ActionMailer::Base.deliveries, :count).by(1)
      end

      it "includes all accounts in the CSV" do
        csv_content = mail.attachments.first.body.to_s
        expect(csv_content).to include("12345")
        expect(csv_content).to include("67890")
      end
    end

    context "with filter_params parameter", feature_setting: { account_tabs: true } do
      let(:suspended_account) { create(:nufs_account, :with_account_owner, owner:, suspended_at: Time.current) }

      before do
        [account1, account2, suspended_account].each do |acc|
          acc.facilities << facility unless acc.facilities.include?(facility)
        end
      end

      context "with suspended filter" do
        let(:mail) { described_class.search_result(email, "", facility, filter_params: { suspended: "true" }).deliver_now }

        it "only includes suspended accounts" do
          csv_content = mail.attachments.first.body.to_s
          expect(csv_content).to include(suspended_account.account_number)
          expect(csv_content).not_to include("12345")
          expect(csv_content).not_to include("67890")
        end
      end

      context "with account_status active filter" do
        let(:mail) { described_class.search_result(email, "", facility, filter_params: { account_status: "active" }).deliver_now }

        it "only includes active accounts" do
          csv_content = mail.attachments.first.body.to_s
          expect(csv_content).to include("12345")
          expect(csv_content).to include("67890")
          expect(csv_content).not_to include(suspended_account.account_number)
        end
      end

      context "with account type filter" do
        let(:other_account_type_class) { Account.config.account_types.find { |type| type != "NufsAccount" } }
        let(:other_account_type) do
          if other_account_type_class
            acc = create(other_account_type_class.underscore.to_sym, :with_account_owner, owner: owner)
            acc.facilities << facility unless acc.facilities.include?(facility)
            acc
          end
        end
        let(:mail) { described_class.search_result(email, "", facility, filter_params: { account_type: "NufsAccount" }).deliver_now }

        before do
          other_account_type if other_account_type_class
        end

        it "only includes accounts of the specified type" do
          csv_content = mail.attachments.first.body.to_s
          expect(csv_content).to include("12345")
          expect(csv_content).to include("67890")
          if other_account_type
            expect(csv_content).not_to include(other_account_type.account_number)
          end
        end
      end
    end
  end
end
