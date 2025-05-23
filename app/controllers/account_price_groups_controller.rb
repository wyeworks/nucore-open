# frozen_string_literal: true

class AccountPriceGroupsController < ApplicationController
  before_action :authenticate_user!

  def show
    @price_groups = account.price_groups
  end
end
