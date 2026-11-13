# frozen_string_literal: true

class BulkAccountMembershipCreator
  USER_ROLE = AccountUser::ACCOUNT_ADMINISTRATOR

  attr_reader :error, :account_users

  def initialize(accounts:, user:, acting_user:)
    @accounts = accounts
    @user = user
    @acting_user = acting_user
  end

  def perform
    @account_users = ActiveRecord::Base.transaction do
      @accounts.map do |account|
        account_user = AccountUser.create!(
          account:,
          user: @user,
          user_role: USER_ROLE,
          created_by_user: @acting_user,
        )
        LogEvent.log(account_user, :create, @acting_user)
        account_user
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    @error = e
    false
  end
end
