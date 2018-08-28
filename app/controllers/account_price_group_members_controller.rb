# frozen_string_literal: true

class AccountPriceGroupMembersController < ApplicationController

  include PriceGroupMembersController
  include SearchHelper

  before_action :authorize_account_price_group_member!, only: [:new, :create, :destroy]

  # GET /facilities/:facility_id/price_groups/:price_group_id/account_price_group_members/search_results
  def search_results
    @limit = 25
    set_search_conditions if params[:search_term].present?
    render layout: false
  end

  private

  def account
    @account ||= Account.find(params[:account_id])
  end

  def after_create_redirect
    redirect_to [current_facility, @price_group]
  end

  def after_destroy_redirect
    redirect_to facility_price_group_path(current_facility, @price_group)
  end

  def create_flash_arguments # TODO: very similar to UserPriceGroupMembersController#create_flash_arguments
    {
      account_number: price_group_member.account.account_number,
      price_group_name: @price_group.name,
    }
  end

  def price_group_member # TODO: very similar to UserPriceGroupMembersController#price_group_member
    @account_price_group_member.account ||= account
    @account_price_group_member.price_group ||= @price_group
    @account_price_group_member
  end

  def search_conditions
    @search_conditions ||= [
      "LOWER(account_number) LIKE ?",
      generate_multipart_like_search_term(params[:search_term]),
    ]
  end

  def set_search_conditions
    @accounts = Account.for_facility(current_facility)
                       .where(search_conditions)
                       .order(:account_number)
                       .limit(@limit)
  end

  def authorize_account_price_group_member!
    @price_group_ability.authorize! action_name, AccountPriceGroupMember
  end

end
