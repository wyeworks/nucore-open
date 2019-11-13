module LdapAuthentication

  class UserLookup

    def call(username)
      entry = UserEntry.find(username)
      entry.to_user if entry
    end

  end

end
