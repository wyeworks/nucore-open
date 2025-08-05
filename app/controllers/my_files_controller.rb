# frozen_string_literal: true

class MyFilesController < ApplicationController

  customer_tab :all
  before_action { @active_tab = "my_files" }
  # Prevent access while acting as, otherwise the facility staff could get
  # access to other facilities' files.
  before_action :check_acting_as

  def index
    @files = current_user.stored_files
                         .merge(Order.purchased)
                         .order(id: :desc).paginate(page: params[:page])
  end

end
