# frozen_string_literal: true

module UmassCorum

  class SubsidyAccount < ::Account

    def self.funding_source_account_numbers
      [173276, 173289, 181597]
    end

    # The SubsidyAccount has its funding source's account set as its
    # `account_number`. `JournalRowBuilder#validate_account` expects for
    # `account.account_number` to be the account_number of a SpeedTypeAccount,
    # making in necessary for SubsidyAccount#account_number to be valid 
    # SpeedTypeAccount account number
    def funding_source
      UmassCorum::SpeedTypeAccount.find_by(account_number: account_number)
    end
  end

end
