# frozen_string_literal: true

class AccountConfig

  # Returns an array of all subclassed Account object names - including global,
  # per-facility, and statement account types.
  # Engines can append to this list.
  def account_types
    @account_types ||= ["NufsAccount"]
  end

  # Returns an array of subclassed Account object names that are available
  # across facilities. Derived from other lists.
  # Engines should NOT append to this list.
  def global_account_types
    account_types - facility_account_types
  end

  # Returns an array of subclassed Account object names that are only available
  # on a per-facility basis.
  # Engines can append to this list.
  def facility_account_types
    @facility_account_types ||= []
  end

  # Account subclasses names that are facility accounts and can be
  # managed globally by specifying which facilities they belong to.
  def facility_account_globally_managed_types
    @facility_account_globally_managed_types ||= []
  end

  # Returns an array of subclassed Account object names that support statements.
  # Engines can append to this list.
  def statement_account_types
    @statement_account_types ||= []
  end

  def reconcilable_account_types
    basic_account_types = (statement_account_types - creation_disabled_types)

    if SettingsHelper.feature_on?(:show_reconcile_credit_cards)
      basic_account_types << "CreditCardAccount"
    end

    basic_account_types.uniq.map(&:constantize).select(&:reconcilable?).map(&:to_s)
  end

  # Returns an array of subclassed Account object names that support affiliates.
  # Engines can append to this list.
  def affiliate_account_types
    @affiliate_account_types ||= []
  end

  # Returns an array of subclassed Account object names that support journal.
  # Engines can append to this list.
  def journal_account_types
    @journal_account_types ||= ["NufsAccount"]
  end

  # An array of account types where creation should be disabled
  def creation_disabled_types
    @creation_disabled_types ||= ["CreditCardAccount"]
  end

  def creation_enabled_types
    account_types - creation_disabled_types
  end

  def creation_enabled?(type)
    type.to_s.in?(account_types - creation_disabled_types)
  end

  # Given an subclassed `Account` name return a param-friendly string. Replaces
  # any backslashes with underscore to support namespaced class names.
  def account_type_to_param(account_type)
    account_type.to_s.underscore.tr("/", "_")
  end

  # Given a subclassed `Account` name, return a string that will be used for routing.
  # Will convert something like `CreditCardAccount` to `credit_cards`
  def account_type_to_route(class_string)
    account_type_to_param(class_string).sub(/_account\z/, "").pluralize
  end

  # Returns an array of subclassed Account objects given a facility.
  # Facility can be a NullObject (used when not in the context of a facility)
  # and the NullObject always returns `true` for cross_facility?.
  def account_types_for_facility(facility, action)
    types = account_types
    types = types.select { |type| globally_managed?(type) } if facility.try(:cross_facility?)
    types -= creation_disabled_types if action == :create
    types
  end

  # Returns true if multiple account types are available
  def multiple_account_types?
    account_types.size > 1
  end

  # Returns true if statements are enabled. Some downstream repositories may
  # not use statements anywhere in the app.
  def statements_enabled?
    statement_account_types.present?
  end

  # Returns true if affiliates are enabled. Some downstream repositories may
  # not use affiliates anywhere in the app.
  def affiliates_enabled?
    affiliate_account_types.present?
  end

  # Returns true if this account type is limited to a single facility.
  def per_facility?(account_type)
    facility_account_types.include?(to_account_class(account_type))
  end

  # Returns true if this account type can cross multiple facilities.
  def global?(account_type)
    global_account_types.include?(to_account_class(account_type))
  end

  def globally_managed?(account_type)
    accounts = global_account_types + facility_account_globally_managed_types

    accounts.include?(to_account_class(account_type))
  end

  # Returns true if this account type supports affiliate.
  def using_affiliate?(account_type)
    affiliate_account_types.include?(to_account_class(account_type))
  end

  # Returns true if this account type supports statements.
  def using_statements?(account_type)
    statement_account_types.include?(to_account_class(account_type))
  end

  # Returns true if this account type supports journal.
  def using_journal?(account_type)
    journal_account_types.include?(to_account_class(account_type))
  end

  def to_account_class(account_type)
    account_type.to_s.classify
  end

end
