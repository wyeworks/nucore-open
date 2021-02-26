# frozen_string_literal: true

module UmassCorum

  # Credit card or PO accounts for external users with a voucher.
  # This allows the CC or PO to be charged a reduced price,
  # with the remaining cost charged against the VoucherAccount.
  # The Mass Innovation Voucher Program (MIVP) is for external customers
  # These are essentially mini-grants that cover 50% or 75% of the usage
  # fees depending on the size of the company.
  #
  # Behaves like a ReconcilableAccount with a customized reconciliation flow
  # See vendor/engines/umass_corum/config/routes.rb and voucher_splits_reconciliation_controller.rb
  class VoucherSplitAccount < SplitAccounts::SplitAccount

    attr_accessor :primary_subaccount_id, :mivp_percent

    delegate :remittance_information, to: :primary_subaccount

    def self.available_accounts_options(current_facility)
      Account.per_facility.for_facility(current_facility).excluding_split_accounts.active
    end

    def self.mivp_percent_options
      [50, 75]
    end

    def mivp_split
      # see VoucherSplitAccountBuilder#setup_default_splits
      splits.find_by(apply_remainder: true)
    end

    def primary_split
      # see VoucherSplitAccountBuilder#setup_default_splits
      splits.find_by(apply_remainder: false)
    end

    def primary_subaccount
      primary_split.subaccount
    end

    def primary_payment_info
      if primary_subaccount.type == "PurchaseOrderAccount"
        primary_subaccount.account_number
      else
        primary_subaccount.description
      end
    end

    def cc_split?
      primary_subaccount.type == "CreditCardAccount"
    end

  end

end
