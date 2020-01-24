# frozen_string_literal: true

class EveryoneGetsAnIndex < ActiveRecord::Migration[4.2]

  def change
    add_index :account_users,       :user_id
    add_index :orders,              :facility_id
    add_index :product_users,       :user_id
    add_index :external_service_passers, :external_service_id
    add_index :external_service_passers, [:passer_id, :passer_type], name: :i_external_passer_id
    add_index :external_service_receivers, :external_service_id
    add_index :external_service_receivers, [:receiver_id, :receiver_type], name: :i_external_receiver_id
    add_index :journal_rows, :journal_id
    add_index :journal_rows, :order_detail_id
    add_index :notifications, :user_id
    add_index :order_details, :problem
    add_index :orders, :state
    add_index :price_policies, :product_id
    add_index :product_access_groups, :product_id
    add_index :product_access_schedule_rules, :product_access_group_id
    add_index :product_access_schedule_rules, :schedule_rule_id
    add_index :product_accessories, :product_id
    add_index :product_accessories, :accessory_id
    add_index :products, :url_name
    add_index :reservations, [:product_id, :reserve_start_at]
    add_index :statement_rows, :statement_id
    add_index :statement_rows, :order_detail_id
    add_index :statements, :account_id
  end

end
