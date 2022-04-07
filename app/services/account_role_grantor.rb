# frozen_string_literal: true

class AccountRoleGrantor

  attr_reader :account, :by

  def initialize(account, by:)
    @account = account
    @by = by
  end

  def grant(user, role)
    account_user = nil

    begin
      AccountUser.transaction do
        # Remove the old owner if we're assigning a new one
        destroy_old_account_user(account.owner, validate: false) if role == AccountUser::ACCOUNT_OWNER

        # Delete any previous role the user might have had
        old_account_user = AccountUser.find_by(account: account, user: user, deleted_at: nil)
        destroy_old_account_user(old_account_user, validate: old_account_user.user_role != AccountUser::ACCOUNT_OWNER) if old_account_user

        account_user = account.account_users.build(
          account: account,
          user: user,
          deleted_at: nil,
          user_role: role,
          created_by_user: by,
        )

        account_user.save!
      end
    rescue ActiveRecord::RecordInvalid # rubocop:disable Lint/HandleExceptions
      # do nothing
    end
    account_user
  end

  private

  def destroy_old_account_user(account_user, validate: true)
    return unless account_user

    account_user.deleted_at = Time.current
    account_user.deleted_by = by.id
    account_user.save!(validate: validate)
  end

end
