# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::GlobalUserRolesReport do

  subject(:report) { described_class.new(users: users) }
  let(:users) { create_list(:user, 3, :global_billing_administrator) }
  let(:report_users) { report.report_data_query }

  describe "for an item" do
    it "exports correct number of line items" do
      expect(report.to_csv.split("\n").length).to eq(4)
    end

    it "populates the report" do
      expect(report).to have_column_values(
        "Name" => report_users.map(&:full_name),
        "Username" => report_users.map(&:username),
        "Email" => report_users.map(&:email),
        "Roles" => report_users.map(&:global_role_list),
      )
    end
  end

end
