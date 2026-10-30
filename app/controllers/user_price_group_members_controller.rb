# frozen_string_literal: true

class UserPriceGroupMembersController < ApplicationController
  include PriceGroupMembersController

  before_action :authorize_user_price_group_member!

  private

  def after_create_redirect
    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  def after_destroy_redirect
    redirect_to users_facility_price_group_path(current_facility, @price_group)
  end

  def create_flash_arguments
    {
      full_name: price_group_member.user.full_name,
      price_group_name: @price_group.name,
    }
  end

  def price_group_member
    @user_price_group_member.user ||= User.find(params[:user_id])
    @user_price_group_member.price_group ||= @price_group
    @user_price_group_member
  end

  def authorize_user_price_group_member!
    @price_group_ability.authorize!(action_name, UserPriceGroupMember)
  end
end
