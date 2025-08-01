# frozen_string_literal: true

class PublicController < ApplicationController

  skip_before_action :authenticate_user!

  def index
    flash.keep
    redirect_to(controller: "facilities", action: "index")
  end

  def switch_back
    session[:acting_user_id] = nil
    ref_url = session[:acting_ref_url] || facilities_url
    session[:acting_ref_url] = nil
    redirect_to ref_url
  end

end
