# frozen_string_literal: true

require_relative "boot"

# Manually require logger,
# see github.com/rails/rails/pull/54264
require "logger"

require "rails/all"
require "will_paginate/array"
require "active_storage/engine"
require_relative "../lib/nucore/exceptions_app"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore

  class Application < Rails::Application

    config.load_defaults 6.1

    # TODO- clean up unconventional inverse relations
    config.active_record.has_many_inversing = false

    # It appears cancancan and/or delayed_job_active_record do some monkey patching of AR incorrectly,
    # so setting this in an initializer doesn't work. https://stackoverflow.com/a/39153224
    config.active_record.belongs_to_required_by_default = false

    # Rails 5 disables autoloading in production by default.
    # https://blog.bigbinary.com/2016/08/29/rails-5-disables-autoloading-after-booting-the-app-in-production.html
    config.enable_dependency_loading = true

    # Needed on the 6.1.6.1 version bump.
    # https://github.com/rails/rails/blob/dc1242fd5a4d91e63846ab552a07e19ebf8716ac/activerecord/CHANGELOG.md
    config.active_record.yaml_column_permitted_classes = [Symbol, ActiveSupport::HashWithIndifferentAccess]

    # ** Please read carefully, this must be configured in config/application.rb **
    # Change the format of the cache entry.
    # Changing this default means that all new cache entries added to the cache
    # will have a different format that is not supported by Rails 6.1 applications.
    # Only change this value after your application is fully deployed to Rails 7.0
    # and you have no plans to rollback.
    config.active_support.cache_format_version = 7.0

    # ** Please read carefully **
    # Disables the deprecated #to_s override in some Ruby core classes
    # See https://guides.rubyonrails.org/configuring.html#config-active-support-disable-to-s-conversion for more information.
    config.active_support.disable_to_s_conversion = true

    # config.time_zone = "Central Time (US & Canada)"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    # config.eager_load_paths << Rails.root.join("extras")
    # config.autoload_paths += Dir["#{config.root}/lib"]
    # config.eager_load_paths += Dir["#{config.root}/lib"]

    config.autoload_paths += Dir["#{config.root}/app/models/external_services"]
    config.eager_load_paths += Dir["#{config.root}/app/models/external_services"]

    # The default locale is :en and all translations under config/locales/ are auto-loaded
    # But we want to make sure anything in the override folder happens at the very end
    # In Rails 7, the application by default overloads nested locales, so we do not need to override the load_path in the application.rb
    # https://blog.saeloun.com/2021/07/20/rails-7-allows-nested-locales/
    # In order to ensure overrides are loaded last, we need to store them outside of config/locales.  See https://github.com/rails/rails/pull/41872#issuecomment-1083413346
    initializer "nucore.i18n.move_overrides_to_end", after: "text_helpers.i18n.add_load_paths" do
      config.i18n.load_path += Dir[Rails.root.join("config", "override_locales", "*.{rb,yml}").to_s]
    end

    config.active_job.queue_adapter = :delayed_job

    config.time_zone = Settings.time_zone

    config.active_record.observers = :order_detail_observer

    # Override the default ("#{Rails.root}/**/spec/mailers/previews") to also load
    # previews from within our engines.
    config.action_mailer.preview_path = "#{Rails.root}/**/spec/mailers/previews"
    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

    # Prevent invalid (usually malicious) URLs from causing exceptions/issues
    config.middleware.insert 0, Rack::UTF8Sanitizer

    config.action_dispatch.rescue_responses.merge!(
      "NUCore::PermissionDenied" => :forbidden,
      "CanCan::AccessDenied" => :forbidden
    )

    config.exceptions_app = Nucore::ExceptionsApp.new(routes)

    config.active_storage.variant_processor = :vips

    # Indicate to the browser that an image should be lazily loaded
    config.action_view.image_loading = "lazy"
  end

end
