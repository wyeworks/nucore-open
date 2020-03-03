class AccountMembershipCloner

  PROTECTED_USER_ROLE = AccountUser::ACCOUNT_OWNER
  ALT_FOR_PROTECTED_ROLE = AccountUser::ACCOUNT_ADMINISTRATOR

  attr_reader :error

  def initialize(account_users_to_clone:, clone_to_user:, acting_user:)
    @account_users_to_clone = account_users_to_clone
    @clone_to_user = clone_to_user
    @acting_user = acting_user
  end

  def perform
    perform!
  rescue => e
    @error = e
    false
  end

  private

  def perform!
    ActiveRecord::Base.transaction do
      @account_users_to_clone.map do |au|
        new_account_user = create_account_user(
          account_id: au.account_id,
          original_role: au.user_role,
        )
        create_log_event(new_account_user)
        new_account_user
      end
    end
  end

  def create_account_user(account_id:, original_role:)
    AccountUser.create!(
      user: @clone_to_user,
      account_id: account_id,
      created_by_user: @acting_user,
      user_role: assign_user_role(original_role)
    )
  end

  # An account can have one and only one owner. If we're cloning an owner, we will
  # clone it as a business admin
  def assign_user_role(role)
    role == PROTECTED_USER_ROLE ? ALT_FOR_PROTECTED_ROLE : role
  end

  def create_log_event(account_user)
    LogEvent.log(account_user, :create, @acting_user)
  end

end
