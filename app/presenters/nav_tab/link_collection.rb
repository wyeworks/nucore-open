# frozen_string_literal: true

class NavTab::LinkCollection

  include Rails.application.routes.url_helpers
  include TranslationHelper

  attr_reader :ability, :facility, :user

  delegate :single_facility?, to: :facility

  def initialize(facility, ability, user)
    @facility = facility || Facility.cross_facility
    @ability = ability
    @user = user
  end

  def self.tab_methods
    @tab_methods ||= %i(
      admin_orders
      admin_reservations
      admin_billing
      admin_products
      admin_users
      admin_reports
      admin_facility
    )
  end

  def admin
    admin_only
  end

  def customer
    [orders, reservations, payment_sources, files]
  end

  def home_button
    if SettingsHelper.feature_on?(:use_manage)
      use
    else
      home
    end
  end

  private

  def payment_sources
    NavTab::Link.new(
      tab: :payment_sources,
      text: t_my(Account),
      subnav: [accounts, transactions, transactions_in_review],
    )
  end

  def accounts
    NavTab::Link.new(tab: :accounts, text: t_my(Account), url: accounts_path)
  end

  def transactions
    NavTab::Link.new(tab: :transactions, text: I18n.t("pages.transactions"), url: transactions_path)
  end

  def transactions_in_review
    count = user.administered_order_details.in_review.count
    NavTab::Link.new(tab: :transactions_in_review, text: I18n.t("pages.transactions_in_review", count: count), url: in_review_transactions_path)
  end

  def files
    NavTab::Link.new(tab: :my_files, text: I18n.t("views.my_files.index.header"), url: my_files_path) if SettingsHelper.feature_on?(:my_files)
  end

  def admin_billing
    if single_facility? && ability.can?(:manage_billing, facility)
      NavTab::Link.new(tab: :admin_billing, url: billing_tab_landing_path)
    end
  end

  def admin_only
    self.class.tab_methods.map do |tab_method|
      send(tab_method)
    end.select(&:present?)
  end

  def admin_orders
    if single_facility? && ability.can?(:administer, Order)
      NavTab::Link.new(tab: :admin_orders, url: facility_orders_path(facility))
    end
  end

  def admin_products
    if single_facility? && ability.can?(:administer, Product)
      NavTab::Link.new(tab: :admin_products, url: facility_products_path(facility))
    end
  end

  cattr_accessor(:report_tab_subnav) { [:general_reports, :instrument_utilization_reports] }

  def admin_reports
    if single_facility? && ability.can?(:manage, Reports::ReportsController)
      NavTab::Link.new(
        tab: :admin_reports,
        subnav: report_tab_subnav.map { |method_name| send(method_name) },
      )
    end
  end

  def admin_reservations
    if single_facility? && ability.can?(:administer, Reservation)
      NavTab::Link.new(
        tab: :admin_reservations,
        url: timeline_facility_reservations_path(facility),
      )
    end
  end

  def admin_users
    if single_facility? && ability.can?(:administer, User)
      NavTab::Link.new(tab: :admin_users, url: facility_users_path(facility))
    end
  end

  def admin_facility
    if single_facility? && ability.can?(:edit, facility)
      NavTab::Link.new(tab: :admin_facility, url: manage_facility_path(facility))
    end
  end

  def billing_tab_landing_path
    facility_transactions_path(facility)
  end

  def general_reports
    NavTab::Link.new(
      text: I18n.t("pages.general_reports"),
      url: facility_general_reports_path(facility, report_by: :product),
    )
  end

  def use
    url = facility ? facility_path(facility) : root_path
    NavTab::Link.new(tab: :use, url: url)
  end

  def manage
    NavTab::Link.new(text: I18n.t("pages.manage", model: Facility.model_name.human(count: 2)), url: list_facilities_url)
  end

  def instrument_utilization_reports
    NavTab::Link.new(
      text: I18n.t("pages.instrument_utilization_reports"),
      url: facility_instrument_reports_path(facility, report_by: :instrument),
    )
  end

  def orders
    NavTab::Link.new(tab: :orders, text: t_my(Order), url: orders_path)
  end

  def reservations
    NavTab::Link.new(
      tab: :reservations,
      text: t_my(Reservation),
      url: reservations_path,
    )
  end

  def home
    NavTab::Link.new(tab: :home, url: root_path)
  end

end
