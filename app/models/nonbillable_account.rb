# frozen_string_literal: true

class NonbillableAccount < Account
  before_validation :set_owner, :set_description, :set_created_by, :set_account_number, :set_expries_at

  # Since this account can be used by anyone, we only need one in the system
  # so this class method should be used to access it.
  def self.singleton_instance
    first || create
  end

  def account_open?(_account_number)
    true
  end

  def can_be_used_by?(_user)
    true
  end

  # with_facility is only used in PurchaseOrderAccount#to_s
  def to_s(with_owner = false, flag_suspended = true, with_facility: false)
    desc = description
    desc += " / #{owner_user_name}" if with_owner && owner_user.present?
    desc += " (#{display_status.upcase})" if flag_suspended && suspended?
    desc
  end

  private

  def set_account_number
    return if account_number
    self.account_number = "non-billable-account"
  end

  def set_description
    return if description
    self.description = "Nonbillable Account"
  end

  def set_expries_at
    return if expires_at
    self.expires_at = 75.years.from_now
  end

  def set_created_by
    return if created_by
    self.created_by = nonbillable_account_owner.id
  end

  def set_owner
    return if owner

    account_users << AccountUser.new(
      user_role: AccountUser::ACCOUNT_OWNER,
      user: nonbillable_account_owner,
      created_by_user: nonbillable_account_owner,
    )
  end

  def nonbillable_account_owner
    User.find_or_create_by!(nonbillable_account_owner_attrs)
  end

  def nonbillable_account_owner_attrs
    {
      username: Settings.nonbillable_user.username,
      first_name: "Nonbillable",
      last_name: "User",
      email: Settings.nonbillable_user.email,
    }
  end

end
