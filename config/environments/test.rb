# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.after_initialize do
    Bullet.enable                     = true
    Bullet.bullet_logger              = true
    Bullet.raise                      = true # raise an error if n+1 query occurs
    Bullet.skip_user_in_notification  = true

    # Skipped rules
    Bullet.add_safelist type: :counter_cache, class_name: "Order", association: :order_details
    Bullet.add_safelist type: :counter_cache, class_name: "OrderDetail", association: :child_order_details
    Bullet.add_safelist type: :counter_cache, class_name: "PriceGroup", association: :account_price_group_members
    Bullet.add_safelist type: :counter_cache, class_name: "PriceGroup", association: :user_price_group_members
    Bullet.add_safelist type: :counter_cache, class_name: "SangerSequencing::Submission", association: :samples
    Bullet.add_safelist type: :counter_cache, class_name: "Schedule", association: :products
    Bullet.add_safelist type: :counter_cache, class_name: "Statement", association: :order_details

    Bullet.add_safelist type: :n_plus_one_query, class_name: "AccountUser", association: :account
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Account", association: :owner
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Account", association: :owner_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "AccountUser", association: :user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "AccountPriceGroupMember", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "AdminReservation", association: :order_detail
    Bullet.add_safelist type: :n_plus_one_query, class_name: "BundleProduct", association: :product
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Instrument", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Instrument", association: :alert
    Bullet.add_safelist type: :n_plus_one_query, class_name: "InstrumentPricePolicy", association: :duration_rates
    Bullet.add_safelist type: :n_plus_one_query, class_name: "InstrumentPricePolicy", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Item", association: :alert
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Item", association: :current_offline_reservations
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Item", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Item", association: :price_policies
    Bullet.add_safelist type: :n_plus_one_query, class_name: "ItemPricePolicy", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "NufsAccount", association: :owner
    Bullet.add_safelist type: :n_plus_one_query, class_name: "NufsAccount", association: :owner_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "NufsAccount", association: :price_group_members
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :cross_core_project
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :created_by_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :merge_order
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :order_details
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Order", association: :user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :account
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :assigned_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :bundle
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :child_order_details
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :created_by_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :external_service_receiver
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :journal
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :occupancy
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :order
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :order_status
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :price_policy
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :product
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :product_accessory
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :project
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :reservation
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderDetail", association: :statement
    Bullet.add_safelist type: :n_plus_one_query, class_name: "OrderStatus", association: :parent
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PriceGroup", association: :account_price_group_members
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PriceGroup", association: :order_details
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PriceGroup", association: :user_price_group_members
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PriceGroupDiscount", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "ProductDisplayGroup", association: :products
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Project", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Project", association: :orders
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PurchaseOrderAccount", association: :facilities
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PurchaseOrderAccount", association: :owner
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PurchaseOrderAccount", association: :owner_user
    Bullet.add_safelist type: :n_plus_one_query, class_name: "PurchaseOrderAccount", association: :price_group_members
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Reservation", association: :product
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SangerSequencing::Submission", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SangerSequencing::Submission", association: :order
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SangerSequencing::Submission", association: :order_detail
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SangerSequencing::Submission", association: :samples
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Schedule", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Schedule", association: :products
    Bullet.add_safelist type: :n_plus_one_query, class_name: "ScheduleRule", association: :product_access_groups
    Bullet.add_safelist type: :n_plus_one_query, class_name: "ServicePricePolicy", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Statement", association: :account
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Statement", association: :facility
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Statement", association: :order_details
    Bullet.add_safelist type: :n_plus_one_query, class_name: "Statement", association: :statement_rows
    Bullet.add_safelist type: :n_plus_one_query, class_name: "TimedServicePricePolicy", association: :duration_rates
    Bullet.add_safelist type: :n_plus_one_query, class_name: "TimedServicePricePolicy", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "User", association: :facilities
    Bullet.add_safelist type: :n_plus_one_query, class_name: "User", association: :price_groups
    Bullet.add_safelist type: :n_plus_one_query, class_name: "User", association: :user_roles

    Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :owner
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :owner_user
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Account", association: :user
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Estimate", association: :estimate_details
    Bullet.add_safelist type: :unused_eager_loading, class_name: "EstimateDetail", association: :product
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Instrument", association: :current_offline_reservations
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Instrument", association: :facility
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Instrument", association: :schedule_rules
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Item", association: :current_offline_reservations
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Journal", association: :journal_rows
    Bullet.add_safelist type: :unused_eager_loading, class_name: "NufsAccount", association: :owner
    Bullet.add_safelist type: :unused_eager_loading, class_name: "NufsAccount", association: :owner_user
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Order", association: :user
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :account
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :assigned_user
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :bundle
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :product
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :occupancy
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :order
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :order_status
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :reservation
    Bullet.add_safelist type: :unused_eager_loading, class_name: "OrderDetail", association: :statement
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Reservation", association: :order
    Bullet.add_safelist type: :unused_eager_loading, class_name: "Service", association: :current_offline_reservations
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SecureRoomPricePolicy", association: :price_group
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SecureRoomPricePolicy", association: :duration_rates
    Bullet.add_safelist type: :n_plus_one_query, class_name: "SecureRoom", association: :alert

    # Rails 7.2 ActiveStorage automatically includes :record association
    Bullet.add_safelist type: :unused_eager_loading, class_name: "ActiveStorage::Attachment", association: :record
  end

  # Settings specified here will take precedence over those in config/application.rb.

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.enable_reloading = false

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    "Cache-Control" => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  config.action_mailer.perform_caching = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Store uploaded files on the local file system in a temporary directory
  config.active_storage.service = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations
  config.i18n.raise_on_missing_translations = true

  # Raise exceptions for disallowed deprecations.
  config.active_support.disallowed_deprecation = :raise

  # Tell Active Support which deprecation messages to disallow.
  config.active_support.disallowed_deprecation_warnings = []

  # Annotate rendered view with file names.
  # config.action_view.annotate_rendered_view_with_filenames = true

  config.active_job.queue_adapter = :test

  Rails.application.routes.default_url_options =
    config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  Delayed::Worker.delay_jobs = false

  config.assets.compile = false if ENV["RAILS_TEST_COMPILED_ASSETS"].present?
  config.active_record.async_query_executor = :inline
end
