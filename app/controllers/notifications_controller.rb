# frozen_string_literal: true

class NotificationsController < ApplicationController

  customer_tab  :all
  before_action :check_acting_as
  before_action :check_notifications

  def index
  end

  private

  def check_notifications
    @notices = current_user.notifications.active

    if @notices.none?
      flash[:notice] = I18n.t "controllers.notifications.no_notices"

      redirect_back(fallback_location: root_path)
    end
  end

end
