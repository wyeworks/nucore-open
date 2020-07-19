# frozen_string_literal: true

namespace :users do
  desc "Retreives users that have been active in the past year as CSV"
  task list_active: :environment do
    finder = Users::ActiveUserFinder.new
    puts finder.active_users_csv(1.year.ago)
  end

  namespace :convert do
    # Usage:
    # Dry run: rake users:convert:external_to_internal[sst123@example.org,netid123]
    # Commit: rake users:convert:external_to_internal[sst123@example.org,netid123,true]
    desc "Convert an external user to internal"
    task :external_to_internal, [:email, :netid, :commit] => :environment do |_t, args|
      options = { dryrun: !args[:commit], logger: Logger.new(STDOUT) }
      options.merge!(lookup: LdapAuthentication::UserLookup.new) if EngineManager.engine_loaded?("ldap_authentication")
      Users::ConvertExternalToInternalUser.new(args[:email], args[:netid], **options).convert!
    end

    # Dry run: rake users:convert:internal_to_external[netid123]
    # Commit: rake users:convert:internal_to_external[netid123,true]
    desc "Convert an internal user to external"
    task :internal_to_external, [:netid, :commit] => :environment do |_t, args|
      options = { dryrun: !args[:commit], logger: Logger.new(STDOUT) }
      Users::ConvertInternalToExternalUser.new(args[:netid], **options).convert!
    end
  end
end
