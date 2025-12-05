# frozen_string_literal: true

class UserPasswordController < ApplicationController

  skip_before_action :authenticate_user!, except: [:edit_current]
  before_action :no_user_allowed, only: [:reset]
  layout "application"
  # GET /users/password/edit_current
  # POST /users/password/edit_current
  def edit_current
    @user = current_user

    unless @user.password_updatable?
      render(:no_password, layout: "application") && return
    end

    if request.post? && @user.update_password_confirm_current(params[:user])
      @user.clean_up_passwords
      flash[:notice] = I18n.t("user_password.edit.success")
      redirect_to new_user_session_path
    end
  end

  def reset
    if request.post? && params[:user]
      @user = User.find_by("LOWER(email) = LOWER(?)", params[:user][:email])
      if @user
        if @user.password_updatable?
          @user.send_reset_password_instructions
          flash[:notice] = I18n.t("user_password.reset.success", email: @user.email)
          redirect_to new_user_session_path
        else
          flash.now[:error] = I18n.t("activerecord.errors.models.user.password_not_updatable")
        end
      else
        flash.now[:error] = I18n.t("user_password.reset.not_found", email: params[:user][:email])
      end
    end
  end

  private

  def no_user_allowed
    if current_user
      redirect_to action: :edit_current
      return false
    end
  end

end
