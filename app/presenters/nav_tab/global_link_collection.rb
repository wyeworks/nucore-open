# frozen_string_literal: true

class NavTab::GlobalLinkCollection
  include Rails.application.routes.url_helpers

  attr_reader :ability

  delegate :can?, to: :ability

  def initialize(ability)
    @ability = ability
  end

  cattr_accessor(:link_collection) do
    [
      :admin_cross_facility_users,
      :global_settings,
      :admin_cross_facility_billing,
    ]
  end

  def links
    link_collection.map { |method_name| send(method_name) }.select(&:present?)
  end

  private

  def admin_cross_facility_billing
    if can?(:manage_billing, Facility.cross_facility)
      global_tab(:admin_billing, facility_transactions_path("all"))
    end
  end

  def admin_cross_facility_users
    if can?(:manage_accounts, Facility.cross_facility) || can?(:manage_users, Facility.cross_facility)
      global_tab(:admin_users, facility_users_path("all"))
    end
  end

  def global_settings
    global_tab(:global_settings, affiliates_path) if can?(:manage, :all)
  end

  def global_tab(tab, url)
    NavTab::Link.new(cross_facility: true, tab: tab, url: url)
  end
end
