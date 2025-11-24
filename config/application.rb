require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Nucore
  class Application < Rails::Application
    config.load_defaults 8.0

    # TODO- clean up unconventional inverse relations
    config.active_record.has_many_inversing = false

    config.active_record.belongs_to_required_by_default = false

    # Needed on the 6.1.6.1 version bump.
    # https://github.com/rails/rails/blob/dc1242fd5a4d91e63846ab552a07e19ebf8716ac/activerecord/CHANGELOG.md
    config.active_record.yaml_column_permitted_classes = [Symbol, ActiveSupport::HashWithIndifferentAccess]

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

    # Add app/lib to load path for manual requires (e.g., in routes.rb)
    $LOAD_PATH.unshift Rails.root.join("app", "lib")

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.eager_load_paths << Rails.root.join("extras")

    config.time_zone = Settings.time_zone

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
