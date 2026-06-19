# frozen_string_literal: true

##
# Permissions granted based on FacilityUserPermission model
class FacilityUserPermissionAbility
  include CanCan::Ability

  attr_reader :user, :resource, :controller

  def initialize(user, resource, controller = nil)
    @user = user
    @resource = resource
    @controller = controller

    grant_permissions
  end

  def facility
    @facility ||=
      case resource
      when Facility then resource
      when OrderDetail, Project then resource.facility
      when Reservation then resource.product.facility
      end
  end

  def grant_permissions
    return unless SettingsHelper.feature_on?(:granular_permissions)

    return unless facility

    facility_user_permission = user.facility_user_permissions.find_by(facility:)
    return unless facility_user_permission&.read_access?

    facility_user_permission.active_permissions.each do |permission|
      send("grant_#{permission}")
    end
  end

  def grant_read_access
    can [:list, :dashboard, :show], Facility

    can [:administer, :index, :show, :tab_counts], Order
    can :show, OrderDetail

    can [:administer, :index, :show, :timeline, :tab_counts], Reservation

    can [:administer, :index, :view_details, :schedule, :show], Product
    can :read, ProductDisplayGroup
    can :read, Schedule
    can :index, [BundleProduct, ScheduleRule, ProductAccessory, ProductAccessGroup]
    can [:index, :product_survey], StoredFile
    can [:instrument_status, :instrument_statuses], Instrument

    can [:show, :index], PriceGroup
    can :read, PriceGroupProduct
    can [:show, :index], [PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ServicePricePolicy]

    can :index, Project

    can [:administer], User
    can :index, User if controller.is_a?(FacilityUsersController) || controller.is_a?(UsersController)
  end

  def grant_assign_permissions
    can :manage, FacilityUserPermission
    can :update, Facility
    can :manage, FacilityAccount
    can :manage, PriceGroup
    can :manage, [AccountPriceGroupMember, UserPriceGroupMember]
    can :manage, PriceGroupProduct
    can :manage, OrderStatus
  end

  def grant_billing_send
    can :manage_billing, facility
    can [:disputed_orders, :transactions, :reassign_chart_strings, :confirm_transactions], Facility
  end

  def grant_billing_journals
    can :manage_billing, facility
    can :manage, [Journal, Statement, OrderDetail]
    can [:send_receipt, :show], Order
    can [:accounts, :index, :orders, :show, :administer], User
    can :manage, AccountUser
    can [:disputed_orders, :movable_transactions, :transactions, :reassign_chart_strings, :move_transactions], Facility
    can :manage, Account do |account|
      account.global? || account.account_facility_joins.any? { |af| af.facility_id == facility.id }
    end
  end

  def grant_product_edition
    can :manage, [
      BundleProduct,
      ProductAccessGroup,
      ProductAccessory,
      ProductDisplayGroup,
      ProductUser,
      Schedule,
      ScheduleRule,
      StoredFile,
      TrainingRequest,
      OfflineReservation,
    ]
    can [:update, :destroy], Product
    cannot :create_daily_booking, Product
    can [:show, :index], PriceGroup
    can [:show, :index], [PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ServicePricePolicy]
    can [:read, :edit], PriceGroupProduct
    can [:index, :create, :destroy], ProductResearchSafetyCertificationRequirement
  end

  def grant_product_creation
    can :create, Product
  end

  def grant_product_pricing
    can :manage, [PricePolicy, InstrumentPricePolicy, ItemPricePolicy, ServicePricePolicy]
    can :manage, PriceGroup
    can :manage, PriceGroupProduct
    can :manage, PriceGroupDiscount
  end

  def grant_order_management
    can :update, OrderDetail, { order: { facility_id: facility.id } }
    can :mark_unrecoverable, OrderDetail, { order: { facility_id: facility.id } }

    can [:administer, :assign_price_policies_to_problem_orders, :batch_update,
         :create, :index, :order_in_past, :send_receipt, :show, :tab_counts, :update], Order

    can :manage, Reservation if resource.is_a?(Reservation)

    can [:administer, :assign_price_policies_to_problem_orders, :batch_update,
         :cancel, :edit, :index, :show, :tab_counts,
         :timeline, :update], Reservation

    can :show_problems, [Order, Reservation]

    can :act_as, Facility
    can(:switch_to, User, &:active?)
    can :read, Notification

    can [:transactions], Facility
    can :manage, OrderImport

    can [:upload_sample_results, :destroy], StoredFile do |fileupload|
      fileupload.file_type == "sample_result"
    end
  end

  def grant_price_adjustment
    can :adjust_price, OrderDetail, { order: { facility_id: facility.id } }
    can :transactions, Facility
    can [:show, :orders], User
  end

  def grant_instrument_management
    can :manage, OfflineReservation
    can :switch, Instrument

    can :manage, Reservation if resource.is_a?(Reservation)

    can [:administer, :assign_price_policies_to_problem_orders, :batch_update,
         :cancel, :create, :edit, :edit_admin, :index, :show, :tab_counts,
         :timeline, :update, :update_admin], Reservation
    can(:destroy, Reservation, &:admin?)
    can :read, ProductAccessory
  end

  def grant_account_management
    can :manage, Account
    can :manage, AccountUser
  end

  def grant_reporting
    can :manage, Reports::ReportsController
  end

  def grant_project_management
    can [:show, :edit, :update], Project, facility_id: facility.id
    can [:create, :new, :cross_core_orders], Project
  end

  def grant_quoting
    return if SettingsHelper.feature_off?(:show_estimates_option)

    can :manage, Estimate, facility_id: facility.id
  end

  def grant_user_management
    can :manage_users, facility
    can :manage, User if controller.is_a?(FacilityUsersController)

    if controller.is_a?(UsersController)
      can [:read, :create, :new, :new_external, :search,
           :access_list, :access_list_approvals, :edit, :update,
           :unexpire, :orders, :accounts], User
    end
  end

  def grant_bulk_email
    return unless defined?(BulkEmail)

    can :send_bulk_emails, facility
  end
end
