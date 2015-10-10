class InitialSchema < ActiveRecord::Migration
  def self.up
    # This migration is handling the fact that the initial commits on nucore
    # had a schema.rb that already had many of the migrations (up to 20110216205725)
    # already run on it, so a rake db:migrate from scratch would not work. This
    # file is reverse-engineered to allow db:migrate to work. For existing forks
    # with existing databases, this migration should not be run.
    return if ActiveRecord::Base.connection.table_exists? "accounts"

    create_table "accounts" do |t|
      t.string   "type",                         :limit => 50,                                 :null => false
      t.string   "account_number",               :limit => 50,                                 :null => false
      t.integer  "owner_user_id" # This gets removed in a later migration
    end

    create_table "facilities" do |t|
      t.string   "name",              :limit => 200,                                                 :null => false
      t.string   "abbreviation",      :limit => 50,                                                  :null => false
      t.string   "url_name",          :limit => 50,                                                  :null => false
      t.string   "account"
      t.boolean  "is_active",                        :precision => 1, :scale => 0,                   :null => false
      t.datetime "created_at",                                                                       :null => false
      t.datetime "updated_at",                                                                       :null => false
      t.text     "description"
      t.string   "pers_affiliate_id" # Only here to support removing it in a later migration
    end

    add_index "facilities", ["abbreviation"], :name => "sys_c008532", :unique => true
    add_index "facilities", ["name"], :name => "sys_c008531", :unique => true
    add_index "facilities", ["url_name"], :name => "sys_c008533", :unique => true

    create_table "nucs_accounts" do |t|
      t.string "value",     :limit => 16,  :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_accounts", ["value"], :name => "index_nucs_accounts_on_value"

    create_table "nucs_chart_field1s" do |t|
      t.string "value",     :limit => 16,  :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_chart_field1s", ["value"], :name => "i_nucs_chart_field1s_value"

    create_table "nucs_departments" do |t|
      t.string "value",     :limit => 16,  :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_departments", ["value"], :name => "i_nucs_departments_value"

    create_table "nucs_funds" do |t|
      t.string "value",     :limit => 8,   :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_funds", ["value"], :name => "index_nucs_funds_on_value"

    create_table "nucs_gl066s" do |t|
      t.string   "budget_period", :limit => 8,  :null => false
      t.string   "fund",          :limit => 8,  :null => false
      t.string   "department",    :limit => 16, :null => false
      t.string   "project",       :limit => 16, :null => false
      t.string   "activity",      :limit => 16, :null => false
      t.string   "account",       :limit => 16, :null => false
      t.datetime "starts_at"
      t.datetime "expires_at"
    end

    add_index "nucs_gl066s", ["account"], :name => "index_nucs_gl066s_on_account"
    add_index "nucs_gl066s", ["activity"], :name => "index_nucs_gl066s_on_activity"
    add_index "nucs_gl066s", ["department"], :name => "i_nucs_gl066s_department"
    add_index "nucs_gl066s", ["fund"], :name => "index_nucs_gl066s_on_fund"
    add_index "nucs_gl066s", ["project"], :name => "index_nucs_gl066s_on_project"

    create_table "nucs_grants_budget_trees" do |t|
      t.string   "account",              :limit => 16, :null => false
      t.string   "account_desc",         :limit => 32, :null => false
      t.string   "roll_up_node",         :limit => 32, :null => false
      t.string   "roll_up_node_desc",    :limit => 32, :null => false
      t.string   "parent_node",          :limit => 32, :null => false
      t.string   "parent_node_desc",     :limit => 32, :null => false
      t.datetime "account_effective_at",               :null => false
      t.string   "tree",                 :limit => 32, :null => false
      t.datetime "tree_effective_at",                  :null => false
    end

    add_index "nucs_grants_budget_trees", ["account"], :name => "i_nuc_gra_bud_tre_acc"

    create_table "nucs_programs" do |t|
      t.string "value",     :limit => 8,   :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_programs", ["value"], :name => "index_nucs_programs_on_value"

    create_table "nucs_project_activities" do |t|
      t.string "project",   :limit => 16,  :null => false
      t.string "activity",  :limit => 16,  :null => false
      t.string "auxiliary", :limit => 512
    end

    add_index "nucs_project_activities", ["activity"], :name => "i_nuc_pro_act_act"
    add_index "nucs_project_activities", ["project"], :name => "i_nuc_pro_act_pro"

    create_table "order_statuses" do |t|
      t.string  "name",        :limit => 50,                                :null => false
      t.integer "facility_id",               :precision => 38, :scale => 0
      t.integer "parent_id",                 :precision => 38, :scale => 0
      t.integer "lft",                       :precision => 38, :scale => 0
      t.integer "rgt",                       :precision => 38, :scale => 0
    end

    add_index "order_statuses", ["facility_id", "parent_id", "name"], :name => "sys_c008542", :unique => true

    create_table "price_group_members" do |t|
      t.string  "type",           :limit => 50,                                :null => false
      t.integer "price_group_id",               :precision => 38, :scale => 0, :null => false
      t.integer "user_id",                      :precision => 38, :scale => 0
      t.integer "account_id",                   :precision => 38, :scale => 0
    end

    create_table "price_groups" do |t|
      t.integer "facility_id",                 :precision => 38, :scale => 0
      t.string  "name",          :limit => 50,                                :null => false
    end

    add_index "price_groups", ["facility_id", "name"], :name => "sys_c008577", :unique => true

    create_table "price_policies" do |t|
      t.string   "type",                :limit => 50,                                :null => false
      t.integer  "instrument_id",                     :precision => 38, :scale => 0
      t.integer  "service_id",                        :precision => 38, :scale => 0
      t.integer  "item_id",                           :precision => 38, :scale => 0
      t.integer  "price_group_id",                    :precision => 38, :scale => 0, :null => false
      t.datetime "start_date",                                                       :null => false
      t.decimal  "unit_cost",                         :precision => 10, :scale => 2
      t.decimal  "unit_subsidy",                      :precision => 10, :scale => 2
      t.decimal  "usage_rate",                        :precision => 10, :scale => 2
      t.integer  "usage_mins",                        :precision => 38, :scale => 0
      t.decimal  "reservation_rate",                  :precision => 10, :scale => 2
      t.integer  "reservation_mins",                  :precision => 38, :scale => 0
      t.decimal  "overage_rate",                      :precision => 10, :scale => 2
      t.integer  "overage_mins",                      :precision => 38, :scale => 0
      t.decimal  "minimum_cost",                      :precision => 10, :scale => 2
      t.decimal  "cancellation_cost",                 :precision => 10, :scale => 2
      t.integer  "reservation_window",                :precision => 38, :scale => 0
    end

    create_table "products" do |t|
      t.string   "type",                    :limit => 50,                                 :null => false
      t.integer  "facility_id",                            :precision => 38, :scale => 0, :null => false
      t.string   "name",                    :limit => 200,                                :null => false
      t.string   "url_name",                :limit => 50,                                 :null => false
      t.text     "description"
      t.boolean  "requires_approval",                      :precision => 1,  :scale => 0, :null => false
      t.integer  "initial_order_status_id",                :precision => 38, :scale => 0
      t.boolean  "is_archived",                            :precision => 1,  :scale => 0, :null => false
      t.boolean  "is_hidden",                              :precision => 1,  :scale => 0, :null => false
      t.datetime "created_at",                                                            :null => false
      t.datetime "updated_at",                                                            :null => false
      t.string   "relay_ip",                :limit => 15
      t.integer  "relay_port",                             :precision => 38, :scale => 0
      t.boolean  "auto_logout",                            :precision => 1,  :scale => 0
      t.integer  "min_reserve_mins",                       :precision => 38, :scale => 0
      t.integer  "max_reserve_mins",                       :precision => 38, :scale => 0
      t.integer  "min_cancel_hours",                       :precision => 38, :scale => 0
      t.string   "unit_size"
    end

    add_index "products", ["relay_ip", "relay_port"], :name => "sys_c008555", :unique => true

    create_table "roles" do |t|
      t.string "name"
    end

    create_table "schedule_rules" do |t|
      t.integer "instrument_id",    :precision => 38, :scale => 0,                  :null => false
      t.decimal "discount_percent", :precision => 10, :scale => 2, :default => 0.0, :null => false
      t.integer "start_hour",       :precision => 38, :scale => 0,                  :null => false
      t.integer "start_min",        :precision => 38, :scale => 0,                  :null => false
      t.integer "end_hour",         :precision => 38, :scale => 0,                  :null => false
      t.integer "end_min",          :precision => 38, :scale => 0,                  :null => false
      t.integer "duration_mins",    :precision => 38, :scale => 0,                  :null => false
      t.boolean "on_sun",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_mon",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_tue",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_wed",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_thu",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_fri",           :precision => 1,  :scale => 0,                  :null => false
      t.boolean "on_sat",           :precision => 1,  :scale => 0,                  :null => false
    end

    add_foreign_key "price_group_members", "price_groups", :name => "sys_c008583"

    add_foreign_key "price_groups", "facilities", :name => "sys_c008578"

    add_foreign_key "price_policies", "price_groups", :name => "sys_c008589"

    add_foreign_key "products", "facilities", :name => "sys_c008556"

    add_foreign_key "schedule_rules", "products", :name => "sys_c008573", :column => "instrument_id"
  end
end
