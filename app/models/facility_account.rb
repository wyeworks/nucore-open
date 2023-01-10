# frozen_string_literal: true

# A model representing a recharge chart string account.
# These are the accounts that are "recharged" when purchases are made.
#
# account_number - chart string for the account
# revenue_account - an account code that signals the type of transaction expected
class FacilityAccount < ApplicationRecord

  include Accounts::AccountNumberSectionable

  belongs_to :facility

  validates :revenue_account, numericality: { only_integer: true }
  validates :account_number, presence: true, uniqueness: { scope: [:revenue_account, :facility_id], case_sensitive: false }

  scope :active, -> { where(is_active: true) }
  scope :inactive, -> { where(is_active: false) }

  alias_attribute :active, :is_active

  def self.editable_attributes(user)
    if revenue_account_editable_by_user?(user)
      [:is_active, :revenue_account]
    else
      [:is_active]
    end
  end

  def self.revenue_account_editable_by_user?(user)
    SettingsHelper.feature_on?(:revenue_account_editable) && user.administrator?
  end

  def to_s
    if SettingsHelper.feature_on?(:expense_accounts)
      "#{account_number} (#{revenue_account})"
    else
      account_number
    end
  end

  def display_account_number
    account_number + (is_active? ? "" : " (inactive)")
  end

  # Over-rideable from school-specific engines that don't use the expense_accounts feature flag
  def revenue_account_for_journal
    revenue_account
  end

  def method_missing(method_sym, *arguments, &block)
    super # we must call super! Not doing so makes ruby 1.9.2 die a hard death
  rescue NoMethodError => e
    raise e unless account_number
    validator = AccountValidator::ValidatorFactory.instance(account_number)
    raise e unless validator.components.key?(method_sym)
    validator.send(method_sym, *arguments)
  end

  def respond_to?(method_sym, include_private = false)
    return true if super

    begin
      return account_number && AccountValidator::ValidatorFactory.instance(account_number).respond_to?(method_sym)
    rescue
      return false
    end
  end

end
