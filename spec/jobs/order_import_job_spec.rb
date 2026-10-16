# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderImportJob, feature_setting: { "pricing.user_based_price_groups" => true } do
  let(:facility) { create(:setup_facility) }
  let!(:user) { create(:user, username: "sst123@example.com") }
  let!(:item) { create(:setup_item, name: "Example Item", facility:) }
  let!(:account) { create(:nufs_account, :with_account_owner, owner: user) }
  let!(:account_price_group_member) { create(:account_price_group_member, account:, price_group: facility.price_groups.last) }
  let(:yesterday) { I18n.l(1.day.ago.to_date, format: :usa) }
  let(:headers) { "#{I18n.t('order_row_importer.headers.user')},#{I18n.t('Chart_string')},Product Name,Quantity,Order Date,Fulfillment Date,Note,Order,Reference ID" }
  let(:rows) { ["sst123@example.com,#{account.account_number},Example Item,1,#{yesterday},#{yesterday},New 1,,"] }
  let(:file) { create(:csv_stored_file, file: StringIO.new(([headers] + rows).join("\n"))) }
  let(:fail_on_error) { true }
  let(:order_import) do
    OrderImport.create!(facility:, created_by: user.id, upload_file: file, fail_on_error:)
  end
  let(:report_recipient) { "report@example.com" }

  def run_import_job
    perform_enqueued_jobs { described_class.perform_later(order_import, report_recipient) }
  end

  def report_emails
    ActionMailer::Base.deliveries.select { |mail| mail.to == [report_recipient] }
  end

  def report_text
    mail = report_emails.first
    (mail.text_part || mail).body.decoded
  end

  it "imports the orders and emails the report" do
    expect { run_import_job }.to change(Order, :count).by(1)

    expect(order_import.reload).to be_processed
    expect(report_emails.size).to eq(1)
    expect(report_text).to include("The import completed successfully. 1 line items were created.")
  end

  it "sends the report in a separate job" do
    expect { described_class.perform_now(order_import, report_recipient) }
      .to have_enqueued_job(CsvReportEmailJob)
      .with("Reports::OrderImport", report_recipient, order_import:, successes: 1, failures: 0)
  end

  context "when the report email fails and the report job is retried" do
    before do
      attempts = 0
      allow(CsvReportMailer).to receive(:csv_report_email).and_wrap_original do |method, *args|
        attempts += 1
        raise "Mail server unavailable" if attempts == 1

        method.call(*args)
      end
    end

    it "does not import the orders again" do
      expect { run_import_job }.to change(Order, :count).by(1)

      expect(CsvReportMailer).to have_received(:csv_report_email).twice
      expect(report_emails.size).to eq(1)
      expect(report_text).to include("1 line items were created")
    end
  end

  context "when the job runs again for an already processed import" do
    it "does not import the orders or send the report again" do
      run_import_job

      expect { run_import_job }.not_to change(Order, :count)
      expect(report_emails.size).to eq(1)
    end
  end

  context "when another run processes the import first" do
    it "does not import the orders again" do
      stale_order_import = OrderImport.find(order_import.id)
      run_import_job

      expect { stale_order_import.process_upload! }.not_to change(Order, :count)
      expect(stale_order_import.process_upload!).to be(false)
    end
  end

  context "when continuing on errors and the import fails after saving some orders" do
    let(:fail_on_error) { false }
    let(:rows) do
      [
        "sst123@example.com,#{account.account_number},Example Item,1,#{yesterday},#{yesterday},New 1,,",
        "sst123@example.com,#{account.account_number},Invalid Item,1,#{I18n.l(15.days.ago.to_date, format: :usa)},#{yesterday},Invalid,,",
      ]
    end

    before do
      attempts = 0
      allow_any_instance_of(OrderImport).to receive(:store_error_report).and_wrap_original do |method, *args|
        attempts += 1
        raise "Storage unavailable" if attempts == 1

        method.call(*args)
      end
    end

    it "does not duplicate the orders saved before the failure" do
      expect { run_import_job }.to change(Order, :count).by(1)

      expect(order_import.reload).to be_error_file_present
      expect(report_emails.size).to eq(1)
      expect(report_text).to include("1 line item(s) created successfully, 1 failed")
    end
  end
end
