# frozen_string_literal: true

require "rails_helper"

RSpec.describe CsvReportMailer do
  describe ".csv_report_email" do
    let(:email) { ActionMailer::Base.deliveries.last }
    let(:recipient) { "recipient@example.net" }
    let(:rendered_text) { email.parts.first.body.to_s }
    let(:report) do
      double(Reports::OrderImport,
             filename: "test.csv",
             to_csv: "1,2,3\n",
             description: subject_line,
             text_content:,
             has_attachment?: true)
    end
    let(:subject_line) { "Subject Line" }
    let(:text_content) { "Text Content" }

    before { CsvReportMailer.csv_report_email(recipient, report).deliver_now }

    context "mail headers" do
      it "has the expected recipient" do
        expect(email.to).to eq [recipient]
      end

      it "has the expected sender" do
        expect(email.from).to eq [Settings.email.from]
      end

      it "has the expected subject" do
        expect(email.subject).to eq subject_line
      end
    end

    context "mail body" do
      it "has an attachment" do
        expect(email.attachments.count).to eq 1
      end

      it "has the expected text content" do
        expect(rendered_text).to eq text_content
      end
    end
  end
end
