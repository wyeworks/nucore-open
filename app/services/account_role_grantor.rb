# frozen_string_literal: true

class AccountRoleGrantor

  attr_reader :account, :by

  def initialize(account, by:)
    @account = account
    @by = by
  end

  def grant(user, role)
    account_user = AccountUser.new(
      account: account,
      user: user,
      deleted_at: nil,
      user_role: role,
      created_by_user: by,
    )

    begin
      AccountUser.transaction do
        # Remove the old owner if we're assigning a new one
        destroy_old_account_user(account.owner) if role == AccountUser::ACCOUNT_OWNER

        # Delete any previous role the user might have had
        old_account_user = AccountUser.find_by(account: account, user: user, deleted_at: nil)
        destroy_old_account_user(old_account_user) if old_account_user

        # Rails 8 caches associations more aggressively, so we need to reload
        # to ensure validations see the current state after deletions
        account.account_users.reload

        account_user.save!
      end
    rescue ActiveRecord::RecordInvalid # rubocop:disable Lint/HandleExceptions
      # do nothing
    end
    account_user
  end

  private

  def destroy_old_account_user(account_user)
    return unless account_user
    # Use update_attribute to skip validations, since removing an owner
    # would fail the "account must have owner" validation
    account_user.update_attribute(:deleted_at, Time.current)
    account_user.update_attribute(:deleted_by, by.id)
  end

end
