require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore
  class Application < Rails::Application
    config.load_defaults 8.0

    config.active_record.belongs_to_required_by_default = false
    config.active_record.observers = :order_detail_observer

    initializer "nucore.i18n.move_overrides_to_end", after: "text_helpers.i18n.add_load_paths" do
      config.i18n.load_path += Dir[Rails.root.join("config", "override_locales", "*.{rb,yml}").to_s]
    end

    config.action_dispatch.rescue_responses.merge!(
      "NUCore::PermissionDenied" => :forbidden,
      "CanCan::AccessDenied" => :forbidden
    )

    config.exceptions_app = routes

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks daemons])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Rails 8 removed Rails.application.secrets
    # Provide backward compatibility for storage.yml and other code still using secrets
    def secrets
      @secrets ||= begin
        require "active_support/ordered_options"
        secrets = ActiveSupport::OrderedOptions.new

        secrets_file = Rails.root.join("config", "secrets.yml")
        if File.exist?(secrets_file)
          require "erb"
          require "yaml"

          all_secrets = YAML.safe_load(ERB.new(File.read(secrets_file)).result, aliases: true) || {}
          env_secrets = all_secrets[Rails.env]

          if env_secrets
            secrets.merge!(env_secrets.deep_symbolize_keys)
          end
        end

        secrets
      end
    end
  end
end
