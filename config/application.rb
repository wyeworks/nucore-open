require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    config.active_record.belongs_to_required_by_default = false

    config.i18n.load_path += Dir[Rails.root.join("config", "override_locales", "*.{rb,yml}").to_s]

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
    # TODO: Migrate to Rails.application.credentials or Rails.application.config_for
    def secrets
      @secrets ||= begin
        secrets_file = Rails.root.join("config/secrets.yml")
        if File.exist?(secrets_file)
          secrets_hash = YAML.load_file(secrets_file, aliases: true)[Rails.env].with_indifferent_access
          SecretsWrapper.new(secrets_hash)
        else
          SecretsWrapper.new({})
        end
      end
    end
  end

  # Wrapper to provide method access to secrets hash (e.g., secrets.api, secrets.secret_key_base)
  class SecretsWrapper
    def initialize(secrets_hash)
      @secrets = secrets_hash
    end

    def method_missing(method, *_args)
      @secrets[method] || @secrets[method.to_s]
    end

    def respond_to_missing?(method, include_private = false)
      @secrets.key?(method) || @secrets.key?(method.to_s) || super
    end

    delegate :[], to: :@secrets

    def dig(*keys)
      @secrets.dig(*keys)
    end
  end
end
