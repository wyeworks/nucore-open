# frozen_string_literal: true

class PriceGroupsController < ApplicationController

  # TODO: refactor to use PriceGroupMembersController concern, maybe with a new name?

  admin_tab     :all
  before_action :check_acting_as
  before_action :init_current_facility
  before_action :load_price_group_and_ability!, only: [:accounts, :destroy, :edit, :show, :update, :users, :users_search]

  load_and_authorize_resource

  layout "two_column"

  def initialize
    @active_tab = "admin_facility"
    super
  end

  # GET /facilities/:facility_id/price_groups
  def index
    @price_groups = current_facility.price_groups
  end

  # GET /facilities/:facility_id/price_groups/:id
  def show
    redirect_to accounts_facility_price_group_path(current_facility, @price_group)
  end

  # GET /facilities/:facility_id/price_groups/:id/users
  def users
    can_see_price_group_users!

    set_user_members
    @tab = :users

    render action: "show"
  end

  def users_search
    can_see_price_group_users!

    set_user_members(params[:search])
    @tab = :users

    render layout: false
  end

  # GET /facilities/:facility_id/price_groups/:id/accounts
  def accounts
    @account_members = @price_group.account_price_group_members
                                   .includes(:account)
                                   .joins(:account)
                                   .merge(Account.order(:account_number))
    @account_members = paginate(@account_members)
    @tab = :accounts

    render action: "show"
  end

  # GET /price_groups/new
  def new
    @price_group = PriceGroup.new(facility: current_facility)
  end

  # GET /price_groups/:id/edit
  def edit
  end

  # POST /price_groups
  def create
    @price_group = PriceGroup.new(price_group_params.merge(facility: current_facility))
    if @price_group.save
      flash[:notice] = I18n.t("controllers.price_groups.create.notice")
      redirect_to [current_facility, @price_group]
      LogEvent.log(@price_group, :create, current_user)
    else
      render action: "new"
    end
  end

  # PUT /price_groups/:id
  def update
    if @price_group.update(price_group_params)
      flash[:notice] = I18n.t("controllers.price_groups.update.notice")
      redirect_to [current_facility, @price_group]
    else
      render action: "edit"
    end
  end

  # DELETE /price_groups/:id
  def destroy
    raise ActiveRecord::RecordNotFound if @price_group.global?

    begin
      if @price_group.destroy
        LogEvent.log(@price_group, :delete, current_user)
        flash[:notice] = I18n.t("controllers.price_groups.destroy.notice")
      else
        flash[:error] = I18n.t("controllers.price_groups.destroy.error")
      end
    rescue ActiveRecord::ActiveRecordError => e
      puts e.to_yaml
      flash[:error] = e.message
    end
    redirect_to facility_price_groups_url
  end

  private

  def set_user_members(search_term = nil)
    @user_members = @price_group.user_price_group_members
                                .includes(:user)
                                .joins(:user)

    if search_term.present?
      @user_members = @user_members.where("LOWER(users.last_name) LIKE :search OR LOWER(users.first_name) LIKE :search OR LOWER(users.username) LIKE :search", search: search_term.downcase)
    end

    @user_members = @user_members.merge(User.sort_last_first)
    @user_members = paginate(@user_members)
  end

  def can_see_price_group_users!
    unless SettingsHelper.feature_on?(:user_based_price_groups) && @price_group_ability.can?(:read, UserPriceGroupMember)
      raise ActiveRecord::RecordNotFound
    end
  end

  def price_group_params
    params.require(:price_group).permit(:name, :display_order, :is_internal, :is_hidden, :admin_editable, :facility_id)
  end

  def paginate(relation)
    relation.paginate(page: params[:page], per_page: 50)
  end

  def load_price_group_and_ability!
    @price_group = current_facility.price_groups.find(params[:id])
    @price_group_ability = Ability.new(current_user, @price_group, self)
  end

end
