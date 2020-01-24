# frozen_string_literal: true

class SchemaCleanup < ActiveRecord::Migration[4.2]

  def up
    change_column :affiliates, :created_at, :datetime, null: false
    change_column :affiliates, :updated_at, :datetime, null: false

    change_column :external_service_passers, :created_at, :datetime, null: false
    change_column :external_service_passers, :updated_at, :datetime, null: false

    change_column :external_service_receivers, :created_at, :datetime, null: false
    change_column :external_service_receivers, :updated_at, :datetime, null: false

    change_column :external_services, :created_at, :datetime, null: false
    change_column :external_services, :updated_at, :datetime, null: false

    change_column :notifications, :created_at, :datetime, null: false
    change_column :notifications, :updated_at, :datetime, null: false

    change_column :order_imports, :created_at, :datetime, null: false
    change_column :order_imports, :updated_at, :datetime, null: false

    change_column :price_group_products, :created_at, :datetime, null: false
    change_column :price_group_products, :updated_at, :datetime, null: false

    change_column :product_access_groups, :created_at, :datetime, null: false
    change_column :product_access_groups, :updated_at, :datetime, null: false

    change_column :relays, :created_at, :datetime, null: false
    change_column :relays, :updated_at, :datetime, null: false

    change_column :schedules, :created_at, :datetime, null: false
    change_column :schedules, :updated_at, :datetime, null: false

    change_column :statements, :account_id, :integer, null: false

    change_column :statement_rows, :order_detail_id, :integer, null: false
    change_column :statement_rows, :created_at, :datetime, null: false
    change_column :statement_rows, :updated_at, :datetime, null: false

    change_column :users, :created_at, :datetime, null: false
    change_column :users, :updated_at, :datetime, null: false

    change_column :versions, :created_at, :datetime, null: false
    change_column :versions, :updated_at, :datetime, null: false

    remove_column :products, :time_based if column_exists? :products, :time_based
  end

  def down
    change_column :affiliates, :created_at, :datetime, null: true
    change_column :affiliates, :updated_at, :datetime, null: true

    change_column :external_service_passers, :created_at, :datetime, null: true
    change_column :external_service_passers, :updated_at, :datetime, null: true

    change_column :external_service_receivers, :created_at, :datetime, null: true
    change_column :external_service_receivers, :updated_at, :datetime, null: true

    change_column :external_services, :created_at, :datetime, null: true
    change_column :external_services, :updated_at, :datetime, null: true

    change_column :notifications, :created_at, :datetime, null: true
    change_column :notifications, :updated_at, :datetime, null: true

    change_column :order_imports, :created_at, :datetime, null: true
    change_column :order_imports, :updated_at, :datetime, null: true

    change_column :price_group_products, :created_at, :datetime, null: true
    change_column :price_group_products, :updated_at, :datetime, null: true

    change_column :product_access_groups, :created_at, :datetime, null: true
    change_column :product_access_groups, :updated_at, :datetime, null: true

    change_column :relays, :created_at, :datetime, null: true
    change_column :relays, :updated_at, :datetime, null: true

    change_column :schedules, :created_at, :datetime, null: true
    change_column :schedules, :updated_at, :datetime, null: true

    change_column :statement_rows, :created_at, :datetime, null: true
    change_column :statement_rows, :updated_at, :datetime, null: true
    change_column :statement_rows, :order_detail_id, :integer, null: true

    change_column :users, :created_at, :datetime, null: true
    change_column :users, :updated_at, :datetime, null: true

    change_column :versions, :created_at, :datetime, null: true
    change_column :versions, :updated_at, :datetime, null: true
  end

end
