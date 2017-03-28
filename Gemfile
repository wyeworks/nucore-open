source "https://rubygems.org"

git_source(:github) { |repo_name| "git@github.com:#{repo_name}.git" }

## base
gem "rails", "4.2.7.1"
gem "protected_attributes"
gem "rails_config",     "0.3.3"

## database
gem "mysql2",           "~> 0.3.20"
group :oracle do
  gem "ruby-oci8", "~> 2.2.0"
  gem "activerecord-oracle_enhanced-adapter", "~> 1.6.0"
end

## auth
gem "cancancan", "1.15"
gem "devise",           "~> 3.5.10"
gem "devise-encryptable", "~> 0.2.0"
gem "devise_ldap_authenticatable", "~> 0.8.5"

## models
gem "aasm", "~> 4.11.1"
gem "paperclip",        "~> 4.2.0"
gem "vestal_versions",  "1.2.4.3", github: "elzoiddy/vestal_versions"
gem "awesome_nested_set", "3.0.3"
gem "nokogiri",         "~> 1.6.1"
gem "rails-observers"

## views
gem "sass-rails", "~> 5.0.6"
gem "coffee-rails", "~> 4.1.1"
gem "uglifier",     "~> 2.7.2"
gem "therubyracer"
gem "bootstrap-sass",   "~> 2.3.2"
gem "haml",             "~> 4.0.5"
gem "will_paginate", "~> 3.1.5"
gem "dynamic_form",     "~> 1.1.4"
gem "ckeditor", "~> 4.1.6"
gem "jquery-rails"
gem "jquery-ui-rails", "~> 6.0.1"
gem "vuejs-rails"
gem "clockpunch",       "~> 0.1.0"
gem "simple_form", "~> 3.3.1"
gem "font-awesome-rails", "~> 3.2.0"
gem "nested_form_fields"
gem "text_helpers"
gem "chosen-rails"
gem "fine_uploader", path: "vendor/engines/fine_uploader"
gem "rubyzip"

## controllers
gem "prawn",            "0.12"
gem "prawn_rails",      "0.0.11"

## other
gem "delayed_job_active_record", "~> 4.0.1"
gem "fog-aws"
gem "rake"
gem "spreadsheet", "~> 1.1.4"
gem "daemons", "1.1.9"

## custom
gem "bulk_email", path: "vendor/engines/bulk_email"
gem "c2po", "~> 1.0.0", path: "vendor/engines/c2po"
gem "dataprobe", "~> 1.0.0", path: "vendor/engines/dataprobe"
gem "projects", "~> 0.0.1", path: "vendor/engines/projects"
gem "sanger_sequencing", "~> 0.0.1", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", "~> 0.0.1", path: "vendor/engines/split_accounts"
gem "synaccess_connect", "0.2.2", github: "tablexi/synaccess"

group :development do
  gem "coffeelint"
  gem "haml_lint", "~>0.24.0"
  gem "letter_opener"
  gem "rubocop", require: false
  gem "web-console"
end

group :development, :deployment do
  gem "capistrano",         require: false
  gem "capistrano-rails",   require: false
  gem "capistrano-rvm",     require: false
  gem "capistrano-bundler", require: false
end

group :development, :test do
  gem "awesome_print", "1.1.0"
  gem "factory_girl_rails", "~> 4.8.0"
  gem "guard-rspec", require: false
  gem "guard-teaspoon", require: false
  gem "pry-rails", "~> 0.3.4"
  gem "pry-byebug", "~> 3.4.1"
  gem "quiet_assets"
  gem "rspec-rails", "~> 3.5.2"
  gem "rspec-activejob"
  gem "shoulda-matchers",  "~> 2.8.0", require: false
  gem "rspec-collection_matchers"
  gem "single_test", "0.4.0"
  gem "spring"
  gem "spring-commands-rspec"
  gem "teaspoon-jasmine"
  gem "test-unit", "~> 3.0"
  gem "thin"
end

group :test do
  gem "rspec_junit_formatter", "0.2.3"
  gem "ci_reporter_rspec"
  gem "codeclimate_circle_ci_coverage"
  gem "capybara"
  gem "capybara-email"
  gem "poltergeist"
end

group :stage, :production do
  gem "eye-patch", require: false
  gem "exception_notification", "~> 4.0.1"
  gem "lograge"
  gem "logstash-event"
  gem "oj", "~> 2.12.14"
  gem "rollbar"
  gem "unicorn", require: false
  gem "whenever", require: false
end
