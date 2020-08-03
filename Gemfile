# frozen_string_literal: true

source "https://rubygems.org"

ruby File.open(File.expand_path(".ruby-version", File.dirname(__FILE__))) { |f| f.read.chomp }

## base
gem "rails", "5.2.4.3"
gem "sprockets", "< 4" # Temporarily lock as we upgrade
gem "config"
gem "bootsnap", require: false

## database
gem "mysql2"
# To use Oracle, remove the mysql2 gem above and uncomment these lines
# There are fixes for fulltext indexing in the 6.0 master of the gem, but we need
# to backport them to support 5.2.
# gem "activerecord-oracle_enhanced-adapter", git: "https://github.com/jhanggi/oracle-enhanced", branch: "release52"
# gem "ruby-oci8" # only for CRuby users


## auth
gem "cancancan"
gem "devise"
gem "devise-encryptable"

## models
gem "aasm"
gem "paperclip"
gem "paper_trail"
gem "awesome_nested_set"
gem "nokogiri"
gem "rails-observers"
gem "icalendar"
gem "paranoia"

## views
gem "sass-rails"
gem "coffee-rails"
gem "uglifier", "= 4.1.18" # 4.1.19 has an issue https://github.com/mishoo/UglifyJS2/issues/3245
gem "mini_racer"
gem "bootstrap-sass", "~> 2.3.2" # will not upgrade
gem "haml"
gem "will_paginate"
gem "dynamic_form"
gem "ckeditor"
gem "jquery-rails"
gem "jquery-ui-rails"
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

## controllers
gem "prawn"
gem "prawn_rails"
gem "prawn-table"

## other
gem "delayed_job_active_record"
gem "fog-aws"
gem "health_check"
gem "rake"
gem "spreadsheet"
gem "daemons"
gem "ice_cube"

## custom
gem "bulk_email", path: "vendor/engines/bulk_email"
gem "c2po", path: "vendor/engines/c2po"
gem "dataprobe", path: "vendor/engines/dataprobe"
gem "saml_authentication", path: "vendor/engines/saml_authentication"
gem "projects", path: "vendor/engines/projects"
gem "sanger_sequencing", path: "vendor/engines/sanger_sequencing"
gem "secure_rooms", path: "vendor/engines/secure_rooms"
gem "split_accounts", path: "vendor/engines/split_accounts"
gem "synaccess_connect"
gem "umass_corum", path: "vendor/engines/umass_corum"

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
  gem "rubocop", "0.58", require: false
  gem "rubocop-rspec"
  gem "web-console"
end

group :development, :test do
  gem "awesome_print"
  # FactoryBot 5.X has some breaking changes we haven't sorted out
  # https://github.com/tablexi/nucore-open/pull/1865
  gem "factory_bot_rails", "< 5"
  gem "parallel_tests"
  gem "pry-rails"
  gem "pry-byebug"
  gem "rspec-rails"
  gem "rspec-activejob"
  gem "teaspoon-jasmine"
end

group :test do
  gem "capybara"
  gem "capybara-email"
  gem "rails-controller-testing"
  gem "rspec-collection_matchers"
  gem "rspec_junit_formatter"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "single_test"
  gem "webmock"
end

group :staging, :production do
  gem "eye-patch", require: false
  gem "oj"
  gem "rollbar"
  gem "unicorn", require: false
  gem "whenever", require: false
end
