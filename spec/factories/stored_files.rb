# frozen_string_literal: true

FactoryBot.define do
  factory :stored_file do
    swf_uploaded_data { Rack::Test::UploadedFile.new("#{Rails.root}/spec/files/flash_file.swf", "application/x-shockwave-flash") }
    sequence(:name) { |n| "flash_file-#{n}.swf" }
    file_type { "info" }
  end

  factory :csv_stored_file, class: StoredFile do
    file { StringIO.new("c,s,v") }
    file_type { "import_upload" }
    name { "clean_import.csv" }
    association :creator, factory: :user
  end

  trait :template do
    file { StringIO.new("c,s,v") }
    file_type { "template" }
    name { "template.csv" }
    association :creator, factory: :user
  end

  trait :results do
    template
    file_type { "sample_result" }
  end
end
