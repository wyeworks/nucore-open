# frozen_string_literal: true

class GlobalUserRolesController < GlobalSettingsController

  before_action :load_user, only: [:destroy, :edit, :update]

  include CsvEmailAction

  def index
    report = Reports::GlobalUserRolesReport.new(users: User.with_global_roles.sort_last_first)

    respond_to do |format|
      format.html do
        @users = report.users
      end

      format.csv do
        queue_csv_report_email(report)
      end
    end
  end

  def destroy
    destroy_all_global_roles
    redirect_to global_user_roles_url
  end

  def edit
    if @user == current_user
      flash[:error] = translate("self_not_allowed", action: "change")
      redirect_to global_user_roles_url
    end
  end

  def search
  end

  def update
    case
    when params[:roles].blank?
      destroy_all_global_roles
    when @user == current_user
      flash[:error] = translate("self_not_allowed", action: "change")
    else
      assign_global_roles!
      flash[:notice] = translate("update.success", user: @user.username)
    end
  rescue ActiveRecord::RecordInvalid
    flash[:error] = translate("update.failure", user: @user.username)
  ensure
    redirect_to global_user_roles_url
  end

  private

  def assign_global_roles!
    @user.transaction do
      user_roles_to_destroy = @user.user_roles.global.where.not(role: params[:roles])
      user_roles_to_destroy.each { |user_role| LogEvent.log(user_role, :delete, current_user) }
      user_roles_to_destroy.destroy_all

      roles_to_add = params[:roles] - @user.user_roles.global.pluck(:role)
      roles_to_add.each do |role_name|
        user_role = UserRole.create!(user: @user, role: role_name)
        LogEvent.log(user_role, :create, current_user)
      end
    end
  end

  def destroy_all_global_roles
    case
    when @user == current_user
      flash[:error] = translate("self_not_allowed", action: "remove")
    when destroyed = @user.user_roles.global.destroy_all
      destroyed.each { |user_role| LogEvent.log(user_role, :delete, current_user) }
      flash[:notice] = translate("destroy.success", user: @user.username)
    else
      flash[:error] = translate("destroy.failure", user: @user.username)
    end
  end

  def load_user
    @user = User.find(params[:id])
  end

  def translate(key, arguments = {})
    I18n.t("global_user_roles.#{key}", arguments)
  end

end
