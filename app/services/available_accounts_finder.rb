# frozen_string_literal: true

class AvailableAccountsFinder
  def initialize(user, facility, current: nil, current_user: nil)
    @user = user
    @current_user = current_user
    @facility = facility
    @current_account = current
  end

  def accounts
    accounts = @user.accounts.for_facility(@facility).active
    accounts &= @current_user.accounts.for_facility(@facility).active if @current_user
    accounts = accounts.select { |a| @facility.can_pay_with_account?(a) }
    accounts += [@current_account] if @current_account && !accounts.include?(@current_account)
    accounts
  end
  alias to_a accounts
end
