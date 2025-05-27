# frozen_string_literal: true

##
# Requires allowed user to be logged in.
#
# Required lets:
# - action: proc that calls the report endpoint
# - report_class: the report class
#
RSpec.shared_examples "csv email action" do
  it "enqueues a csv report email job" do
    expect { action.call }.to(
      enqueue_job(CsvReportEmailJob).with do |report_name|
        expect(report_name).to eq(report_class.to_s)
      end
    )
  end
end
