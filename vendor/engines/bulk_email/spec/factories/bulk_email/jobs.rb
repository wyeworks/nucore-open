# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_email_job, class: BulkEmail::Job do
    facility
    user
    subject { "Bulk Email Subject Line" }
    body { "Bulk Email Message Body" }
    recipients { %w[r1@example.com r2@example.net r3@example.org] }
    search_criteria do
      {
        "bulk_email" => {
          "user_types" => %w[account_owners authorized_users customers],
        },
        "products" => %w[1 2 3],
        "product_id" => "1",
        "start_date" => "1/1/2016",
        "end_date" => "12/31/2016",
      }
    end
  end
end
