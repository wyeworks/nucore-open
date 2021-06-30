# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::ProductAccessListCsvReport do
  subject(:report) { Reports::ProductAccessListCsvReport.new("Example Product", product_users) }

  describe "#to_csv" do
    context "with no order details" do
      let(:product_users) { ProductUser.none }

      it "generates a header", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(1)
        expect(lines[0]).to eq("Username,Full Name,User Status,Email,Scheduling Group,Date Added\n")
      end

      it "sets the filename based on the passed in product name" do
        expect(report.filename).to eq("example-product_access_list.csv")
      end
    end

    context "with one of each status of product users" do
      let(:facility) { create(:setup_facility) }
      let(:instrument) { create(:setup_instrument, facility: facility, requires_approval: true) }
      let(:admin) { create(:user, :administrator) }
      let(:active_user) { create(:user, username: "active@example.edu") }
      let(:suspended_user) { create(:user, :suspended, username: "suspended@example.edu") }
      let(:expired_user) { create(:user, :expired, username: "expired@example.edu") }
      let(:current_time) { Time.current }
      let(:scheduling_group) { create(:product_access_group, name: "My Scheduling Group", product: instrument) }

      let!(:product_users) do
        [
          ProductUser.create(product: instrument, user: active_user, approved_by: admin.id, approved_at: current_time, product_access_group: scheduling_group),
          ProductUser.create(product: instrument, user: suspended_user, approved_by: admin.id, approved_at: current_time),
          ProductUser.create(product: instrument, user: expired_user, approved_by: admin.id, approved_at: current_time),
        ]
      end

      it "generates a header line and 3 data lines", :aggregate_failures do
        lines = report.to_csv.lines
        expect(lines.count).to eq(4)
        expect(lines[1]).to eq("active@example.edu,#{active_user.full_name},Active,#{active_user.email},My Scheduling Group,#{I18n.l(current_time, format: :usa)}\n")
        expect(lines[2]).to eq("suspended@example.edu,#{suspended_user.full_name},Suspended,#{suspended_user.email},,#{I18n.l(current_time, format: :usa)}\n")
        expect(lines[3]).to eq("expired@example.edu,#{expired_user.full_name},Expired,#{expired_user.email},,#{I18n.l(current_time, format: :usa)}\n")
      end
    end
  end
end
