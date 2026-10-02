# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:all) do
    # users are not created within transactions, so delete them all here before running tests
    PriceGroupMember.delete_all
    UserRole.delete_all
    User.delete_all
    OrderStatus.delete_all

    # initialize order status constants
    OrderStatus.find_or_create_by(name: "New")
    OrderStatus.find_or_create_by(name: "In Process")
    OrderStatus.find_or_create_by(name: "Canceled")
    OrderStatus.find_or_create_by(name: "Complete")
    OrderStatus.find_or_create_by(name: "Reconciled")
    OrderStatus.find_or_create_by(name: "Unrecoverable")

    # initialize affiliates
    Affiliate.OTHER

    # initialize price groups
    @nupg = PriceGroup.setup_global(name: Settings.price_group.name.base, is_internal: true, display_order: 1)
    PriceGroup.setup_global(name: Settings.price_group.name.external, is_internal: false, display_order: 3)
  end
end
