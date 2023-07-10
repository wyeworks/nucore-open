# frozen_string_literal: true

module UmassCorum

  class SubsidyAccount < ::Account

    def self.funding_source_accounts
      UmassCorum::SpeedTypeAccount.where(account_number: funding_source_account_numbers)
    end

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

    def auto_dispute_by
      funding_source_owner
    end

    def funding_source_owner
      funding_source.owner.user
    end

    def global_admin_must_resolve_disputes?
      true
    end

    def administrators
      (super.to_a + [funding_source_owner]).uniq
    end
  end

end
