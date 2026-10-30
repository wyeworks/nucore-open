# frozen_string_literal: true

module SplitAccounts
  class Split < ApplicationRecord
    belongs_to :parent_split_account, class_name: "SplitAccounts::SplitAccount", inverse_of: :splits
    belongs_to :subaccount, class_name: "Account", inverse_of: :parent_splits

    scope :with_apply_remainder, -> { where(apply_remainder: true) }

    validates :parent_split_account, presence: true
    validates :subaccount, presence: true
    validates :percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    validate :not_self_referential
    validate :not_split_subaccount

    def not_self_referential
      return unless parent_split_account == subaccount

      errors.add(:subaccount, :not_self_referential)
    end

    def not_split_subaccount
      return unless subaccount.is_a?(SplitAccounts::SplitAccount)

      errors.add(:subaccount, :not_split_subaccount)
    end

    def self.available_subaccounts
      Account.excluding_split_accounts.global.active
    end
  end
end
