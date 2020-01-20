# frozen_string_literal: true

class InitialSchema < ActiveRecord::Migration[4.2]

  def self.up
    # This migration is handling the fact that the initial commits on nucore
    # had a schema.rb that already had many of the migrations (up to 20110216205725)
    # already run on it, so a rake db:migrate from scratch would not work. This
    # file is reverse-engineered to allow db:migrate to work. For existing forks
    # with existing databases, this migration should not be run.
    return if ActiveRecord::Base.connection.table_exists? "accounts"

    create_table "accounts" do |t|
      t.string   "type",                         limit: 50,                                 null: false
      t.string   "account_number",               limit: 50,                                 null: false
      t.integer  "owner_user_id" # This gets removed in a later migration
    end

    create_table "facilities" do |t|
      t.string   "name",              limit: 200,                                                 null: false
      t.string   "abbreviation",      limit: 50,                                                  null: false
      t.string   "url_name",          limit: 50,                                                  null: false
      t.string   "account"
      t.boolean  "is_active", precision: 1, scale: 0, null: false
      t.datetime "created_at",                                                                       null: false
      t.datetime "updated_at",                                                                       null: false
      t.text     "description"
      t.string   "pers_affiliate_id" # Only here to support removing it in a later migration
    end

    add_index "facilities", ["abbreviation"], unique: true
    add_index "facilities", ["name"], unique: true
    add_index "facilities", ["url_name"], unique: true

    create_table "order_statuses" do |t|
      t.string  "name", limit: 50, null: false
      t.integer "facility_id",               precision: 38, scale: 0
      t.integer "parent_id",                 precision: 38, scale: 0
      t.integer "lft",                       precision: 38, scale: 0
      t.integer "rgt",                       precision: 38, scale: 0
    end

    add_index "order_statuses", %w(facility_id parent_id name), unique: true

    create_table "price_group_members" do |t|
      t.string  "type", limit: 50, null: false
      t.integer "price_group_id",               precision: 38, scale: 0, null: false
      t.integer "user_id",                      precision: 38, scale: 0
      t.integer "account_id",                   precision: 38, scale: 0
    end

    create_table "price_groups" do |t|
      t.integer "facility_id", precision: 38, scale: 0
      t.string  "name", limit: 50, null: false
    end

    add_index "price_groups", %w(facility_id name), unique: true

    create_table "price_policies" do |t|
      t.string   "type", limit: 50, null: false
      t.integer  "instrument_id",                     precision: 38, scale: 0
      t.integer  "service_id",                        precision: 38, scale: 0
      t.integer  "item_id",                           precision: 38, scale: 0
      t.integer  "price_group_id",                    precision: 38, scale: 0, null: false
      t.datetime "start_date",                                                       null: false
      t.decimal  "unit_cost",                         precision: 10, scale: 2
      t.decimal  "unit_subsidy",                      precision: 10, scale: 2
      t.decimal  "usage_rate",                        precision: 10, scale: 2
      t.integer  "usage_mins",                        precision: 38, scale: 0
      t.decimal  "reservation_rate",                  precision: 10, scale: 2
      t.integer  "reservation_mins",                  precision: 38, scale: 0
      t.decimal  "overage_rate",                      precision: 10, scale: 2
      t.integer  "overage_mins",                      precision: 38, scale: 0
      t.decimal  "minimum_cost",                      precision: 10, scale: 2
      t.decimal  "cancellation_cost",                 precision: 10, scale: 2
      t.integer  "reservation_window",                precision: 38, scale: 0
    end

    create_table "products" do |t|
      t.string   "type", limit: 50, null: false
      t.integer  "facility_id", precision: 38, scale: 0, null: false
      t.string   "name",                    limit: 200,                                null: false
      t.string   "url_name",                limit: 50,                                 null: false
      t.text     "description"
      t.boolean  "requires_approval",                      precision: 1,  scale: 0, null: false
      t.integer  "initial_order_status_id",                precision: 38, scale: 0
      t.boolean  "is_archived",                            precision: 1,  scale: 0, null: false
      t.boolean  "is_hidden",                              precision: 1,  scale: 0, null: false
      t.datetime "created_at",                                                            null: false
      t.datetime "updated_at",                                                            null: false
      t.string   "relay_ip", limit: 15
      t.integer  "relay_port",                             precision: 38, scale: 0
      t.boolean  "auto_logout",                            precision: 1,  scale: 0
      t.integer  "min_reserve_mins",                       precision: 38, scale: 0
      t.integer  "max_reserve_mins",                       precision: 38, scale: 0
      t.integer  "min_cancel_hours",                       precision: 38, scale: 0
      t.string   "unit_size"
    end

    add_index "products", %w(relay_ip relay_port), unique: true

    create_table "schedule_rules" do |t|
      t.integer "instrument_id",    precision: 38, scale: 0, null: false
      t.decimal "discount_percent", precision: 10, scale: 2, default: 0.0, null: false
      t.integer "start_hour",       precision: 38, scale: 0,                  null: false
      t.integer "start_min",        precision: 38, scale: 0,                  null: false
      t.integer "end_hour",         precision: 38, scale: 0,                  null: false
      t.integer "end_min",          precision: 38, scale: 0,                  null: false
      t.integer "duration_mins",    precision: 38, scale: 0,                  null: false
      t.boolean "on_sun",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_mon",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_tue",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_wed",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_thu",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_fri",           precision: 1,  scale: 0,                  null: false
      t.boolean "on_sat",           precision: 1,  scale: 0,                  null: false
    end

    add_foreign_key "price_group_members", "price_groups"

    add_foreign_key "price_groups", "facilities"

    add_foreign_key "price_policies", "price_groups"

    add_foreign_key "products", "facilities"

    add_foreign_key "schedule_rules", "products", column: "instrument_id"
  end

end
