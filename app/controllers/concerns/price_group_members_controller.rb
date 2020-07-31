# frozen_string_literal: true

module PriceGroupMembersController

  extend ActiveSupport::Concern

  included do
    admin_tab :all
    before_action :authenticate_user!
    before_action :check_acting_as
    before_action :init_current_facility
    before_action :load_price_group_and_ability!

    layout "two_column"

    load_and_authorize_resource
  end

  def new
  end

  def initialize
    @active_tab = "admin_facility"
    super
  end

  def create
    raise NUCore::PermissionDenied unless @price_group.can_manage_price_group_members?

    if price_group_member.save
      LogEvent.log(price_group_member, :create, current_user, metadata: { member_type: price_group_member.member_type })
      set_flash(:notice, :create, create_flash_arguments)
    else
      set_flash(:error, :create, create_flash_arguments)
    end
    after_create_redirect
  end

  def destroy
    raise NUCore::PermissionDenied unless @price_group.can_manage_price_group_members?

    if destroy_price_group_member!
      LogEvent.log(price_group_member, :delete, current_user, metadata: { member_type: price_group_member.member_type })
      set_flash(:notice, :destroy)
    else
      set_flash(:error, :destroy)
    end
    after_destroy_redirect
  end

  private

  def destroy_price_group_member!
    price_group_member
      .class
      .where(id: params[:id], price_group_id: @price_group.id)
      .destroy_all
  end

  def set_flash(kind, action, arguments = {})
    flash[kind] =
      I18n.t("controllers.#{controller_name}.#{action}.#{kind}", arguments)
  end

  def load_price_group_and_ability!
    @price_group = current_facility.price_groups.find(params[:price_group_id])
    @price_group_ability = Ability.new(current_user, @price_group, self)
  end

end
