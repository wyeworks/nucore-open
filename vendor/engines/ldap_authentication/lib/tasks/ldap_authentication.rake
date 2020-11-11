# frozen_string_literal: true

namespace :ldap_authentication do
  desc "Check status of LDAP users"
  task user_status: :environment do
    User.authenticated_by_netid.unexpired.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)

      puts [
        entry.present? ? "active" : "inactive",
        user.username,
        user.email,
        user.first_name,
        user.last_name,
        user.created_at&.iso8601,
        user.last_sign_in_at&.iso8601,
        user.suspended_at&.iso8601,
      ].join("\t")
    end
  end

  desc "Expire users removed from LDAP directory"
  task expire_removed_users: :environment do
    User.authenticated_by_netid.unexpired.find_each do |user|
      entry = LdapAuthentication::UserEntry.find(user.username)
      if entry.blank?
        puts "Expiring #{user.username}"
        user.update!(expired_at: Time.current, expired_note: "No longer in LDAP directory")
      end
    end
  end

  desc "Updates User records based on LDAP directory"
  task update_users: :environment do
    def update_user_from_ldap(user)
      entry = LdapAuthentication::UserEntry.find(user.username)
      if entry.present?
        LdapAuthentication::UserUpdater.new(user).update_from_ldap
        if user.saved_changes?
          puts "Updated: #{user.username}"
        else
          puts "No changes: #{user.username}"
        end
      end
    rescue NoMethodError => e
      puts "Error for #{user.username}: #{e}"
    end

    updated_user_count = 0
    users_to_update = User.authenticated_by_netid.unexpired
    users_to_update.find_each do |user|
      update_user_from_ldap(user)
      updated_user_count += 1 if user.saved_changes?
    end
    puts "Updated #{updated_user_count} of #{users_to_update.count} Unexpired NetID Users"
  end
end
