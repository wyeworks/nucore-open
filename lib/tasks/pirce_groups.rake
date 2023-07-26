# frozen_string_literal: true

namespace :price_group do
  # This creates a new global price group, if it does not exist, and adds
  # a PriceGroupDiscount for it to every ScheduleRule. If the price group
  # already exists, this will just add PriceGroupDiscounts for it to ScheduleRules
  # that are missing then.
  #
  # rake price_group:add_global_price_group["new group",true,false,15]
  desc "Create a new global price group and/or setup schedule rules for it"
  task :add_global_price_group, [:name, :internal, :admin_editable, :discount] => :environment do |_t, args|
    name = args[:name]
    is_internal = args[:internal].casecmp("true").zero?
    admin_editable = args[:admin_editable].casecmp("true").zero?
    discount_percent = args[:discount] || 0

    PriceGroup.setup_global(name:, is_internal:, admin_editable:, discount_percent:)
  end
end
