# frozen_string_literal: true

class GlobalSettingsController < ApplicationController

  authorize_resource class: NUCore

  layout "two_column"

  def initialize
    @active_tab = "global_settings"
    super
  end

  def admin_tab?
    true
  end

end
