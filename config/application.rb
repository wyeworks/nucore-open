# frozen_string_literal: true

require_relative "boot"

require "rails/all"
require "will_paginate/array"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore

  class Application < Rails::Application

    config.load_defaults 5.0
    # It appears cancancan and/or delayed_job_active_record do some monkey patching of AR incorrectly,
    # so setting this in an initializer doesn't work. https://stackoverflow.com/a/39153224
    config.active_record.belongs_to_required_by_default = false

    # Rails 5 disables autoloading in production by default.
    # https://blog.bigbinary.com/2016/08/29/rails-5-disables-autoloading-after-booting-the-app-in-production.html
    config.enable_dependency_loading = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
    config.autoload_paths += Dir["#{config.root}/app/models/**/"]
    config.autoload_paths += Dir["#{config.root}/app/controllers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/mailers/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]
    config.autoload_paths += Dir["#{config.root}/app/validators"]

    # The default locale is :en and all translations under config/locales/ are auto-loaded
    # But we want to make sure anything in the override folder happens at the very end
    initializer "nucore.i18n.move_overrides_to_end", after: "text_helpers.i18n.add_load_paths" do
      config.i18n.load_path -= Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
      config.i18n.load_path += Dir[Rails.root.join("config", "locales", "override", "*.{rb,yml}").to_s]
    end

    config.active_job.queue_adapter = :delayed_job

    config.time_zone = Settings.time_zone

    config.active_record.observers = :order_detail_observer

    # Override the default ("#{Rails.root}/**/spec/mailers/previews") to also load
    # previews from within our engines.
    config.action_mailer.preview_path = "#{Rails.root}/**/spec/mailers/previews"
  end

end
