# frozen_string_literal: true

require "rails_helper"

RSpec.describe UmassCorum::AdminReports::AccountUserCsvReport do
  subject(:report) { UmassCorum::AdminReports::AccountUserCsvReport.new }

  describe "#to_csv" do
    context "with no users" do
      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0]).to eq("Username,Account Number,URL,Description,Account Type,Account Expired,Account Suspended,Access Revoked,Account Role,Facilities,Full Name,Email\n")
      end

      it "sets the filename based on the passed in product name" do
        expect(report.filename).to eq("account_member_data.csv")
      end
    end

    context "with account_users" do
      let(:facility1) { create(:facility) }
      let(:facility2) { create(:facility) }
      let!(:account1) { create(:account, :with_account_owner, facility: facility1) }
      let(:account2) { create(:account, :with_account_owner, facility: facility2) }
      let(:business_admin_user) { create(:user) }
      let(:purchaser_user) { create(:user) }
      let!(:business_admin_acct_user) { create(:account_user, :business_administrator, user: business_admin_user, account: account2) }
      let!(:purchaser_acct_user) { create(:account_user, :purchaser, user: purchaser_user, account: account2) }
      let!(:inactive_acct_user) { create(:account_user, :purchaser, :inactive, user: purchaser_user, account: account1) }

      it "generates a header line and 3 data lines", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(6)
        expect(lines[1]).to eq("#{account1.owner_user.username},#{account1.account_number},/facilities/#{facility1.url_name}/accounts/#{account1.id},Account description,Payment Source,\"#{account1.expires_at.strftime("%B %e, %Y")}\",\"\",\"\",Owner,#{facility1.name},#{account1.owner_user.full_name},#{account1.owner_user.email}\n")
        expect(lines[2]).to eq("#{account2.owner_user.username},#{account2.account_number},/facilities/#{facility2.url_name}/accounts/#{account2.id},Account description,Payment Source,\"#{account2.expires_at.strftime("%B %e, %Y")}\",\"\",\"\",Owner,#{facility2.name},#{account2.owner_user.full_name},#{account2.owner_user.email}\n")
        expect(lines[3]).to eq("#{business_admin_user.username},#{account2.account_number},/facilities/#{facility2.url_name}/accounts/#{account2.id},Account description,Payment Source,\"#{account2.expires_at.strftime("%B %e, %Y")}\",\"\",\"\",Business Administrator,#{facility2.name},#{business_admin_user.full_name},#{business_admin_user.email}\n")
        expect(lines[4]).to eq("#{purchaser_user.username},#{account2.account_number},/facilities/#{facility2.url_name}/accounts/#{account2.id},Account description,Payment Source,\"#{account2.expires_at.strftime("%B %e, %Y")}\",\"\",\"\",Purchaser,#{facility2.name},#{purchaser_user.full_name},#{purchaser_user.email}\n")
        expect(lines[5]).to eq("#{purchaser_user.username},#{account1.account_number},/facilities/#{facility1.url_name}/accounts/#{account1.id},Account description,Payment Source,\"#{account1.expires_at.strftime("%B %e, %Y")}\",\"\",\"#{inactive_acct_user.deleted_at.strftime("%B %e, %Y")}\",Purchaser,#{facility1.name},#{purchaser_user.full_name},#{purchaser_user.email}\n")
      end
    end
  end
end
