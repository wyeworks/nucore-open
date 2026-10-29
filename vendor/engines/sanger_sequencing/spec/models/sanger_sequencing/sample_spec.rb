# frozen_string_literal: true

require "rails_helper"

RSpec.describe SangerSequencing::Sample do
  it "belongs to a submission" do
    submission = SangerSequencing::Submission.create!
    sample = described_class.create!(submission:, customer_sample_id: "1234")
    expect(sample.submission).to eq(submission)
  end
end
