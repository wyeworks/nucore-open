# frozen_string_literal: true

module LdapAuthentication

  class UserUpdater < SimpleDelegator

    def update_from_ldap
      entry = UserEntry.find(username)
      # Something has gone horribly wrong if the user is not found here.
      raise "User #{username} not found in LDAP after authentication." unless entry

      update_attributes!(entry.attributes)
    rescue ActiveRecord::RecordInvalid => e
      # If the record is invalid (e.g. a duplicate email address), trigger an email
      # notification, but let the user through. Their information will not be updated.
      ActiveSupport::Notifications.instrument(
        "background_error",
        exception: e,
        information: "Could not update User #{username} because of validation errors",
      )
    end

  end

end
