# frozen_string_literal: true

class UserFileUploadsController < ApplicationController
  admin_tab           :all
  before_action       :authenticate_user!
  before_action       :check_acting_as
  before_action       :init_current_facility
  before_action       :set_user

  authorize_resource class: StoredFile

  layout "two_column"

  def index
    @files = @user.file_uploads.where(file_type: "user_info")
    @file = @user.file_uploads.new(created_by: session_user)
  end

  def download
    file = @user.file_uploads.find(params[:id])
    redirect_to file.download_url
  end

  def create
    @files = @user.file_uploads.where(file_type: "user_info")
    @file = @user.file_uploads.new(create_params)

    if @file.save
      flash[:notice] = t(".notice")
      redirect_to [current_facility, @user, :user_file_uploads]
    else
      # This is because paperclip duplicates error messages
      # See: https://github.com/thoughtbot/paperclip/pull/1554 and
      # https://github.com/thoughtbot/paperclip/commit/2aeb491fa79df886a39c35911603fad053a201c0
      @file.errors.delete(:file) unless SettingsHelper.feature_on?(:active_storage)

      render :index
    end
  end

  def destroy
    @file = @user.file_uploads.find(params[:id])

    if @user.file_uploads.destroy(@file)
      flash[:notice] = t(".notice")
    else
      flash[:error] = t(".error")
    end

    redirect_to [current_facility, @user, :user_file_uploads]
  end

  private

  def set_user
    @user = User.find params[:user_id]
  end

  def create_params
    params.require(:stored_file).permit(:name, :file_type, :file).merge(created_by: session_user.id, file_type: "user_info")
  end
end
