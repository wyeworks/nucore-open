# frozen_string_literal: true

module SplitAccounts

  # Contains overrides for building a `SplitAccounts::SplitAccount` from params.
  # Dynamically called via the `AccountBuilder.for()` factory.
  class SplitAccountBuilder < AccountBuilder

    protected

    # Override strong_params for `build` account.
    def account_params_for_build
      [
        :account_number,
        :description,
        { splits_attributes: [:subaccount_id, :percent, :apply_remainder, :_destroy] },
      ]
    end

    # Hooks into superclass's `build` method.
    def after_build
      setup_default_splits if account.splits.none?
      set_expires_at
    end

    private

    # Sets `expires_at` to match the earliest expiring subaccount.
    # Make sure this happens after the splits are built.
    def set_expires_at
      account.expires_at = account.earliest_expiring_subaccount.try(:expires_at)
      # Only set a fallback expires_at when subaccounts aren't present to help
      # suppress unnecesary misleading errors.
      account.expires_at ||= Time.current
      account
    end

    def setup_default_splits
      account.splits.build(percent: 50, apply_remainder: true)
      account.splits.build(percent: 50)
    end

  end

end
