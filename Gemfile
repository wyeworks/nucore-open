# frozen_string_literal: true

source "https://rubygems.org"

ruby File.open(File.expand_path(".ruby-version", File.dirname(__FILE__))) { |f| f.read.chomp }

## base
gem "rails", "~> 7.0.8"
gem "sprockets", "< 4" # Temporarily lock as we upgrade
gem "sprockets-rails", "3.2.2" # downgrade to avoid a bug
gem "config"
gem "bootsnap", require: false
gem "puma"
gem "rack-utf8_sanitizer"
gem "net-smtp"
gem "net-imap"
gem "net-pop"
gem "tzinfo-data"
gem "webrick"

# Remove once we upgrade to rails 7.2.X or greater
# See: github.com/rails/rails/pull/54264
gem "concurrent-ruby", "< 1.3.5"

## database
gem "mysql2"
# To use Oracle, remove the mysql2 gem above and uncomment these lines
# Check initializers/oracle.rb when upgrading
# gem "activerecord-oracle_enhanced-adapter", "~> 6.1.0"
# gem "ruby-oci8" # only for CRuby users

## auth
gem "cancancan", "3.1.0"
gem "devise"
gem "devise-encryptable"
gem "devise-security"

## models
gem "aasm"
# TODO: switch from Paperclip to ActiveStorage
gem "kt-paperclip"
gem "paper_trail"
gem "nokogiri"
gem "rails-observers"
gem "icalendar"
gem "paranoia"

## views
gem "sass-rails"
gem "coffee-rails"
gem "uglifier", "= 4.1.18" # 4.1.19 has an issue https://github.com/mishoo/UglifyJS2/issues/3245
gem "bootstrap-sass", "~> 2.3.2" # will not upgrade
gem "haml"
gem "will_paginate"
# TODO: Remove dynamic_form and use Rails to display errors
gem "dynamic_form"
# 5.0 has breaking changes based which need to be addressed before we can upgrade
gem "ckeditor", "< 5"
gem "jquery-rails"
gem "jquery-ui-rails", "~> 6.0"
gem "vuejs-rails", "~> 1.0.26" # 2.0 introduces breaking changes
gem "clockpunch"
gem "simple_form"
gem "font-awesome-rails"
gem "nested_form_fields"
gem "text_helpers"
gem "chosen-rails"
gem "fine_uploader", path: "vendor/engines/fine_uploader"
gem "fullcalendar", path: "vendor/engines/fullcalendar"
gem "rubyzip"

## PDF generation
gem "prawn-rails"
# https://github.com/prawnpdf/prawn/issues/1195
gem "matrix"

## Email
gem "mailgun-ruby", "~>1.3.2"

## other
gem "delayed_job_active_record"
gem "health_check"
gem "rake"
gem "spreadsheet"
gem "daemons"
gem "ice_cube"
gem "jwt"

# Optional: File uploads to S3
gem "aws-sdk-s3"

# Optional: File uploads to Azure Blob via ActiveStorage
# gem "azure-storage-blob", "~> 2.0", require: false
# only used when SettingsHelper.feature_on?(:active_storage) is true
gem "active_storage_validations"
gem "image_processing", ">= 1.2"

## custom
gem "bulk_email", path: "vendor/engines/bulk_email"
gem "c2po", path: "vendor/engines/c2po"
gem "dataprobe", path: "vendor/engines/dataprobe"
gem "ldap_authentication", path: "vendor/engines/ldap_authentication"
gem "saml_authentication", path: "vendor/engines/saml_authentication"
gem "sanger_sequencing", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", path: "vendor/engines/split_accounts"
gem "synaccess_connect"

group :development do
  gem "bcrypt_pbkdf", ">= 1.0", "< 2.0", require: false # Required to support ed25519 SSH keys for capistrano. https://github.com/net-ssh/net-ssh/issues/565
  gem "bullet" # Detect N+1s and recommends eager loading
  gem "capistrano", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm", require: false
  gem "coffeelint"
  gem "ed25519", ">= 1.2", "< 2.0", require: false # Required to support ed25519 SSH keys for capistrano. https://github.com/net-ssh/net-ssh/issues/565
  gem "haml_lint", require: false
  gem "letter_opener"
  gem "rubocop", "1.74.0", require: false
  gem "rubocop-performance"
  gem "rubocop-rails"
  gem "rubocop-rspec"
  gem "web-console"
end

group :development, :test do
  gem "amazing_print"
  gem "axe-core-rspec"
  gem "factory_bot_rails"
  gem "parallel_tests"
  gem "pry-rails"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rspec-activejob"
  gem "selenium-webdriver"
  gem "teaspoon-jasmine"
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "rails-controller-testing"
  gem "rspec-collection_matchers"
  gem "rspec_junit_formatter"
  gem "shoulda-matchers"
  gem "single_test"
  gem "webmock"
  gem "deprecation_toolkit"
end

group :stage, :production do
  gem "exception_notification"
  gem "eye-patch", require: false
  gem "oj"
  gem "rollbar"
  gem "unicorn", require: false
  gem "whenever", require: false
end
