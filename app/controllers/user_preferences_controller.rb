# frozen_string_literal: true

class UserPreferencesController < ApplicationController

  before_action :check_acting_as

  def index
    UserPreference.create_missing_user_preferences(current_user)
    @user_preferences = current_user.user_preferences
  end

  def edit
    @user_preference = current_user.user_preferences.find(params[:id])
    @user_preference_option = @user_preference.option
  end

  def update
    @user_preference = current_user.user_preferences.find(params[:id])
    if @user_preference.update(user_preference_params)
      redirect_to user_user_preferences_path(current_user)
    else
      render :edit
    end
  end

  def user_preference_params
    params.require(:user_preference).permit(:value)
  end

end
