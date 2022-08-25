# frozen_string_literal: true

module Accounts::AccountNumberSectionable

  extend ActiveSupport::Concern

  module ClassMethods

    def account_number_field_names
      new.account_number_fields.keys
    end

  end

  def account_number_fields
    { account_number: { required: true } }
  end

  def account_number_to_s
    account_number
  end

  def account_number_to_storage_format
    account_number_parts.account_number.to_s
  end

  def account_number_parts
    @account_number_parts
  end

  def account_number_parts=(fields)
    @account_number_parts = OpenStruct.new(fields)
    self.account_number = account_number_to_storage_format
  end

  # Provides the current value of an account number part, or its default value,
  # as provided by `account_number_fields`.
  #
  # Not all account types have multiple account number parts. Account types that
  # only have one part to their `account_number` should only have a part called
  # `:account_number`, in this case, whatever the value of `account_number` is
  # returned.
  def account_number_part_value_or_default(part)
    if part == :account_number
      account_number
    else
      account_number_parts&.dig(part) || account_number_fields[part][:default]
    end
  end

end
