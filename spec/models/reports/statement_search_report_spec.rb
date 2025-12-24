# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reports::StatementSearchReport do
  let(:facility) { create(:setup_facility) }
  let(:account) { create(:nufs_account, :with_account_owner) }
  let(:user) { create(:user) }
  let(:statement) { create(:statement, facility:, account:, created_by: user.id) }
  let(:product) { create(:setup_instrument, facility:) }
  let(:order) { create(:setup_order, product:, account:) }

  let(:search_params) do
    {
      current_facility: facility.url_name,
    }
  end

  subject(:report) { described_class.new(search_params:) }

  before do
    create_list(:order_detail, 2, statement:, order:, product:)
  end

  describe "#to_csv" do
    context "when merged_statement_history_columns feature is OFF", feature_setting: { merged_statement_history_columns: false } do
      it "generates CSV with base headers only" do
        csv_lines = report.to_csv.lines
        header = csv_lines.first

        expect(header).to include(Statement.human_attribute_name(:invoice_number))
        expect(header).to include(Statement.human_attribute_name(:created_at))
        expect(header).to include(Statement.human_attribute_name(:status))
        expect(header).not_to include(I18n.t("statements.closed_at"))
        expect(header).not_to include(I18n.t("statements.closed_by"))
        expect(header).not_to include(I18n.t("statements.reconciled_at"))
      end

      it "generates CSV rows without closed/reconciled columns" do
        csv = CSV.parse(report.to_csv, headers: true)
        row = csv.first

        expect(row[Statement.human_attribute_name(:invoice_number)]).to eq(statement.invoice_number)
        expect(row[I18n.t("statements.closed_at")]).to be_nil
        expect(row[I18n.t("statements.closed_by")]).to be_nil
        expect(row[I18n.t("statements.reconciled_at")]).to be_nil
      end
    end

    context "when merged_statement_history_columns feature is ON", feature_setting: { merged_statement_history_columns: true } do
      let(:closer_user) { create(:user) }
      let(:reconciled_at) { Time.zone.local(2024, 1, 15, 10, 30) }

      before do
        LogEvent.log(statement, :closed, closer_user)
        statement.order_details.update_all(reconciled_at:)
      end

      it "generates CSV with extended headers" do
        csv_lines = report.to_csv.lines
        header = csv_lines.first

        expect(header).to include(Statement.human_attribute_name(:invoice_number))
        expect(header).to include(I18n.t("statements.closed_at"))
        expect(header).to include(I18n.t("statements.closed_by"))
        expect(header).to include(I18n.t("statements.reconciled_at"))
      end

      it "generates CSV rows with closed_at data" do
        csv = CSV.parse(report.to_csv, headers: true)
        row = csv.first

        expect(row[I18n.t("statements.closed_at")]).to be_present
      end

      it "generates CSV rows with closed_by data" do
        csv = CSV.parse(report.to_csv, headers: true)
        row = csv.first

        expect(row[I18n.t("statements.closed_by")]).to eq(closer_user.full_name)
      end

      it "generates CSV rows with reconciled_at data" do
        csv = CSV.parse(report.to_csv, headers: true)
        row = csv.first

        expect(row[I18n.t("statements.reconciled_at")]).to be_present
      end

      context "when there are multiple closed events" do
        let(:another_closer) { create(:user) }

        before do
          LogEvent.log(statement, :closed, another_closer)
        end

        it "joins multiple closed_by names with semicolon" do
          csv = CSV.parse(report.to_csv, headers: true)
          row = csv.first

          expect(row[I18n.t("statements.closed_by")]).to include(closer_user.full_name)
          expect(row[I18n.t("statements.closed_by")]).to include(another_closer.full_name)
          expect(row[I18n.t("statements.closed_by")]).to include("; ")
        end
      end

      context "when statement has no reconciled orders" do
        before do
          statement.order_details.update_all(reconciled_at: nil)
        end

        it "generates empty reconciled_at column" do
          csv = CSV.parse(report.to_csv, headers: true)
          row = csv.first

          expect(row[I18n.t("statements.reconciled_at")]).to eq("")
        end
      end
    end
  end

  describe "#filename" do
    it "returns statements.csv" do
      expect(report.filename).to eq("statements.csv")
    end
  end

  describe "#has_attachment?" do
    it "returns true" do
      expect(report.has_attachment?).to be true
    end
  end
end
