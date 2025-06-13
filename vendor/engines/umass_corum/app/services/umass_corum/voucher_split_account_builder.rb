# frozen_string_literal: true

module UmassCorum

  # Contains overrides for building a `UmassCorum::VoucherSplitAccounts::SplitAccount` from params.
  # Dynamically called via the `AccountBuilder.for()` factory.
  class VoucherSplitAccountBuilder < AccountBuilder

    # Override strong_params for `build` account.
    def account_params_for_build
      [
        :account_number,
        :description,
        :primary_subaccount_id,
        :mivp_percent,
      ]
    end

    # Hooks into superclass's `build` method.
    def after_build
      setup_default_splits
      set_expires_at
    end

    # Over-ride the parent class method,
    # otherwise the controller will look for "umass_corum_voucher_split_account"
    def account_params_key
      @account_params_key ||= "voucher_split_account"
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
      mivp_percent = account_params[:mivp_percent].to_i
      account.splits.build(
        percent: 100 - mivp_percent,
        apply_remainder: false,
        subaccount_id: account_params[:primary_subaccount_id],
      )
      # for the MIVP VoucherAccount
      account.splits.build(
        percent: mivp_percent,
        apply_remainder: true,
        subaccount_id: voucher_account.id,
      )
    end

    def voucher_account
      UmassCorum::VoucherAccount.instance
    end

  end

end
