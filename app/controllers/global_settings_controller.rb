class GlobalSettingsController < ApplicationController

  before_action :authenticate_user!

  authorize_resource :class => NUCore

  layout 'two_column'

  def initialize
    @active_tab = 'global_settings'
    super
  end

end
