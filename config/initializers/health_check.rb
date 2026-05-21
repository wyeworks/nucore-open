# frozen_string_literal: true

# See https://github.com/ianheggie/health_check for more options
HealthCheck.setup do |config|
  config.uri = "healthz"
end

# The gem's migration check scans a single directory via
# `Dir[File.join(db_migrate_path, "[0-9]*_*.rb")]` and misses migrations
# contributed by engines via `initializer :append_migrations`. Without this
# override the gem only sees host migrations under db/migrate/, producing a
# false positive whenever an engine ships the newest migration timestamp.
Rails.application.config.after_initialize do
  HealthCheck::Utils.db_migrate_path =
    "{#{Rails.application.paths['db/migrate'].to_a.join(',')}}"
end
