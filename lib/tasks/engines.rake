# frozen_string_literal: true

namespace :engines do
  namespace :db do
    desc "Run `down` for each migration within an engine. Useful when disabling an engine."
    task :migrate_down, [:engine_name] => :environment do |_t, args|
      engine_name = args[:engine_name]
      path = "vendor/engines/#{engine_name}/db/migrate"
      raise "Invalid engine '#{engine_name}'" unless Dir.exist?(path)

      ActiveRecord::Migrator.migrations(path).reverse.each do |migration|
        ActiveRecord::Migrator.run(:down, path, migration.version)
      end

      Rake::Task["db:schema:dump"].invoke
    end
  end
end
