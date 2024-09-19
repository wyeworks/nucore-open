# frozen_string_literal: true

namespace :order_status do
  # This creates a new "Unrecoverable" order status, if it does not exist.
  #
  # rake order_status:add_unrecoverable_order_status
  desc "Create a Unrecoverable order status"
  task :add_unrecoverable_order_status, [] => :environment do
    OrderStatus.find_or_create_by(name: "Unrecoverable")
  end
end
