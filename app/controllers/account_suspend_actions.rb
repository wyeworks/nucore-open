# frozen_string_literal: true

module AccountSuspendActions

  def suspend
    if @account.suspend
      flash[:notice] = I18n.t("controllers.facility_accounts.suspend.success")
      LogEvent.log(@account, :suspended, current_user)
    else
      flash[:alert] = I18n.t("controllers.facility_accounts.suspend.failure")
    end

    redirect_to open_or_facility_path("account", @account)
  end

  def unsuspend
    if @account.unsuspend
      flash[:notice] = I18n.t("controllers.facility_accounts.unsuspend.success")
      LogEvent.log(@account, :unsuspended, current_user)
    else
      flash[:alert] = I18n.t("controllers.facility_accounts.unsuspend.failure", errors: @account.errors.full_messages.join("\n"))
    end

    redirect_to open_or_facility_path("account", @account)
  end

end
