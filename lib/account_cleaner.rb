# frozen_string_literal: true

class AccountCleaner

  def self.clean_expires_at(account)
    if account.expires_at.seconds_since_midnight == 0
      account.update(expires_at: account.expires_at.end_of_day)
    end
  end

end
