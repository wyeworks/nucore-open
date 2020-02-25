# frozen_string_literal: true

# Builds a subclassed Account object given params.
#
# This class supports extensions from engines via subclassing `AccountBuilder`
# object that are named `#{AccountSubclass}Builder` (i.e. NufsAccountBuilder).
# See `self.for()` for additional detail.
#
# Example usage:
#   factory = AccountBuilder.for("NufsAccount")
#   account = factory.new(...).build
#
class AccountBuilder

  attr_reader :action, :account, :account_params,
              :account_type, :current_user, :facility, :owner_user, :params

  # Initialize the instance variables.
  def initialize(options = {})
    @account = options[:account] # optional, required for update
    @account_type = options[:account_type] # optional, required for build
    @account_params_key = options[:account_params_key] # computed; optional, used for testing
    @current_user = options[:current_user] # required
    @facility = options[:facility] # optional
    @owner_user = options[:owner_user] # optional, required for build
    @params = options[:params] || ActionController::Parameters.new # optional
  end

  # Factory method that returns a subclassed `AccountBuilder` if one exists for
  # the given account_type; otherwise returns `AccountBuilder` class (self).
  # The `account_type` argument accepts an `Account` class object, class name
  # string/symbol, or underscored class name string/symbol.
  #
  # Example usage:
  #   AccountBuilder.for("NufsAccount") => NufsAccountBuilder
  #   AccountBuilder.for("BuilderDoesNotExist") => AccountBuilder
  #
  def self.for(account_type)
    return self if account_type.blank?
    begin
      klass = "#{account_type}_builder".classify
      klass.constantize
    rescue NameError
      self
    end
  end

  # Returns a new account subclassed `Account` object.
  # Can thrown an error if the account_type is invalid.
  def build
    set_action(:build)
    validate_account_type!
    new_account
    assign_params
    build_account_users
    set_affiliate
    set_created_by
    set_facility

    after_build
    account
  end

  # Returns an updated account subclassed `Account` object.
  # Can thrown an error if the account_type is invalid.
  def update
    set_action(:update)
    set_account_type
    validate_account_type!
    assign_params
    set_affiliate
    set_updated_by

    after_update
    account
  end

  # Given an account type, set the account_params_key.
  def account_params_key
    @account_params_key ||= Account.config.account_type_to_param(account_type)
  end

  protected

  # Override this method in subclassed builder to extend `build` functionality.
  def after_build
  end

  # Override this method in subclassed builder to extend `update` functionality.
  def after_update
  end

  # Needs to be overridable by engines
  cattr_accessor(:common_permitted_account_params) { [:description, :reference] }

  # Override in subclassed builder to define additional strong_param attributes
  # for build action. Returns an array of "permitted" params.
  def account_params_for_build
    self.class.common_permitted_account_params + [:account_number]
  end

  # Override in subclassed builder to define additional strong_param attributes
  # for update action. Returns an array of "permitted" params.
  def account_params_for_update
    self.class.common_permitted_account_params.dup
  end

  # Applies strong_param rules to the passed in params based on the current
  # `action`. Assumes params are guarenteed to be an instantiated
  # `ActionController::Parameters` object. Silently returns an empty
  # params hash if the `account_params_key` is missing.
  def account_params
    return ActionController::Parameters.new unless params.key?(account_params_key)
    permitted = send("account_params_for_#{action}")
    params.require(account_params_key).permit(*permitted)
  end

  # Simply assigns the strong_params to the account new/persisted account object.
  def assign_params
    account.assign_attributes(account_params)
    account
  end

  # Validates the account type given the current facility.  Facility can be nil
  # or a null object and this should still work. Throws an
  # ActionController::RoutingError if the account type is invalid.
  def validate_account_type!
    valid_account_types = Account.config.account_types_for_facility(facility, action)
    unless valid_account_types.include?(account_type)
      raise ActionController::RoutingError, "invalid account_type"
    end
  end

  # Creates a new account object given an account type.
  # Should throw a NameError exception if the account_type object doesn't exist.
  def new_account
    @account = account_type.constantize.new
  end

  # Sets the `action` which is used to load the proper set of account_params.
  # The action should always get set before `account_params` is called.
  def set_action(action)
    @action = action
  end

  # Given an account, set the account_type.
  # Only used for `update`.
  def set_account_type
    @account_type = account.class.to_s
  end

  # Build the owner account_user.
  # Only used for `build`.
  def build_account_users
    account.account_users.build(
      user_id: owner_user.id,
      user_role: "Owner",
      created_by: current_user.id,
    )
    account
  end

  # Set the affiliate_id if the account type supports affiliates, the affiliate
  # param is present, and the affiliate exists. Also ensure affiliate_other
  # gets wiped out if the affiliate_id does not point to `Other`.
  def set_affiliate
    if affiliate.present?
      account.affiliate_id = affiliate.id
      account.affiliate_other = affiliate.subaffiliates_enabled? ? account_params[:affiliate_other] : nil
    else
      account.affiliate_id = account.affiliate_other = nil
    end
    account
  end

  # Set the facility if the account type is scoped to facility.
  def set_facility
    return unless account.per_facility? && facility&.id
    account.account_facility_joins.build(facility: facility)
    account
  end

  # Set created_by. Only used for `build`.
  def set_created_by
    account.created_by = current_user.id
    account
  end

  # Set updated_by. Only used for `update`.
  def set_updated_by
    account.updated_by = current_user.id
    account
  end

  private

  def affiliate
    @affiliate ||=
      if account.class.using_affiliate? && account_params.key?(:affiliate_id)
        Affiliate.find_by(id: account_params[:affiliate_id])
      end
  end

end
