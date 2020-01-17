# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_01_13_131617) do

  create_table "account_facility_joins", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id", null: false
    t.integer "account_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_facility_joins_on_account_id"
    t.index ["facility_id"], name: "index_account_facility_joins_on_facility_id"
  end

  create_table "account_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "user_id", null: false
    t.string "user_role", limit: 50, null: false
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by"
    t.index ["account_id"], name: "fk_accounts"
    t.index ["user_id"], name: "index_account_users_on_user_id"
  end

  create_table "accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", limit: 50, null: false
    t.string "account_number", limit: 50, null: false
    t.string "description", limit: 50, null: false
    t.datetime "expires_at", null: false
    t.string "name_on_card", limit: 200
    t.integer "expiration_month"
    t.integer "expiration_year"
    t.datetime "created_at", null: false
    t.integer "created_by", null: false
    t.datetime "updated_at"
    t.integer "updated_by"
    t.datetime "suspended_at"
    t.text "remittance_information"
    t.integer "facility_id"
    t.integer "affiliate_id"
    t.string "affiliate_other"
    t.string "outside_contact_info"
    t.string "ar_number"
    t.index ["affiliate_id"], name: "index_accounts_on_affiliate_id"
    t.index ["facility_id"], name: "fk_account_facility_id"
  end

  create_table "affiliates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "subaffiliates_enabled", default: false, null: false
  end

  create_table "budgeted_chart_strings", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "fund", limit: 20, null: false
    t.string "dept", limit: 20, null: false
    t.string "project", limit: 20
    t.string "activity", limit: 20
    t.string "account", limit: 20
    t.datetime "starts_at", null: false
    t.datetime "expires_at", null: false
  end

  create_table "bulk_email_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id"
    t.integer "user_id", null: false
    t.string "subject", null: false
    t.text "body", null: false
    t.text "recipients", null: false
    t.text "search_criteria", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "fk_rails_37dbedd2b3"
    t.index ["user_id"], name: "fk_rails_7cd8662ccc"
  end

  create_table "bundle_products", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "bundle_product_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.index ["bundle_product_id"], name: "fk_bundle_prod_prod"
    t.index ["product_id"], name: "fk_bundle_prod_bundle"
  end

  create_table "delayed_jobs", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", limit: 4294967295, null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "email_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "key", null: false
    t.datetime "last_sent_at", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "key"], name: "index_email_events_on_user_id_and_key", unique: true
  end

  create_table "external_service_passers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "external_service_id"
    t.integer "passer_id"
    t.string "passer_type"
    t.boolean "active", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_service_id"], name: "index_external_service_passers_on_external_service_id"
    t.index ["passer_id", "passer_type"], name: "i_external_passer_id"
  end

  create_table "external_service_receivers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "external_service_id"
    t.integer "receiver_id"
    t.string "receiver_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "external_id"
    t.text "response_data"
    t.boolean "manages_quantity", default: false, null: false
    t.index ["external_service_id"], name: "index_external_service_receivers_on_external_service_id"
    t.index ["receiver_id", "receiver_type"], name: "i_external_receiver_id"
  end

  create_table "external_services", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type"
    t.string "location"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "facilities", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 200, null: false
    t.string "abbreviation", limit: 50, null: false
    t.string "url_name", limit: 50, null: false
    t.boolean "is_active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
    t.boolean "accepts_cc", default: true
    t.boolean "accepts_po", default: true
    t.boolean "accepts_multi_add", default: false, null: false
    t.text "short_description", null: false
    t.text "address"
    t.string "phone_number"
    t.string "fax_number"
    t.string "email"
    t.string "journal_mask", limit: 50, null: false
    t.boolean "show_instrument_availability", default: false, null: false
    t.string "order_notification_recipient"
    t.boolean "sanger_sequencing_enabled", default: false, null: false
    t.text "banner_notice"
    t.index ["abbreviation"], name: "index_facilities_on_abbreviation", unique: true
    t.index ["is_active", "name"], name: "index_facilities_on_is_active_and_name"
    t.index ["name"], name: "index_facilities_on_name", unique: true
    t.index ["url_name"], name: "index_facilities_on_url_name", unique: true
  end

  create_table "facility_accounts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id", null: false
    t.string "account_number", limit: 50, null: false
    t.boolean "is_active", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "revenue_account", null: false
    t.index ["facility_id"], name: "fk_facilities"
  end

  create_table "instrument_alerts", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "instrument_id", null: false
    t.string "note", limit: 256, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["instrument_id"], name: "index_instrument_alerts_on_instrument_id"
  end

  create_table "instrument_statuses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "instrument_id", null: false
    t.boolean "is_on", null: false
    t.datetime "created_at", null: false
    t.index ["instrument_id", "created_at"], name: "index_instrument_statuses_on_instrument_id_and_created_at"
    t.index ["instrument_id"], name: "fk_int_stats_product"
  end

  create_table "journal_cutoff_dates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "cutoff_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "journal_rows", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "journal_id", null: false
    t.integer "order_detail_id"
    t.string "account"
    t.decimal "amount", precision: 9, scale: 2, null: false
    t.string "description", limit: 512
    t.integer "account_id"
    t.index ["account_id"], name: "index_journal_rows_on_account_id"
    t.index ["journal_id"], name: "index_journal_rows_on_journal_id"
    t.index ["order_detail_id"], name: "index_journal_rows_on_order_detail_id"
  end

  create_table "journals", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id"
    t.string "reference", limit: 50
    t.string "description", limit: 200
    t.boolean "is_successful"
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "updated_by"
    t.datetime "updated_at"
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.datetime "journal_date", null: false
    t.index ["facility_id"], name: "index_journals_on_facility_id"
  end

  create_table "log_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "loggable_id"
    t.string "loggable_type"
    t.string "event_type"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "event_time"
    t.index ["loggable_type", "loggable_id"], name: "index_log_events_loggable"
    t.index ["user_id"], name: "index_log_events_on_user_id"
  end

  create_table "notifications", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", null: false
    t.integer "subject_id", null: false
    t.string "subject_type", null: false
    t.integer "user_id", null: false
    t.string "notice", null: false
    t.datetime "dismissed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id", "subject_type"], name: "index_notifications_on_subject_id_and_subject_type"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "nu_product_cert_requirements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id"
    t.integer "nu_safety_certificate_id"
    t.datetime "deleted_at"
    t.integer "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nu_safety_certificate_id"], name: "index_nu_product_cert_requirements_on_nu_safety_certificate_id"
    t.index ["product_id"], name: "index_nu_product_cert_requirements_on_product_id"
  end

  create_table "nu_safety_certificates", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "deleted_at"
    t.integer "deleted_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_by_id"], name: "index_nu_safety_certificates_on_deleted_by_id"
    t.index ["name"], name: "index_nu_safety_certificates_on_name"
  end

  create_table "order_details", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "order_id", null: false
    t.integer "parent_order_detail_id"
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.integer "price_policy_id"
    t.decimal "actual_cost", precision: 10, scale: 2
    t.decimal "actual_subsidy", precision: 10, scale: 2
    t.integer "assigned_user_id"
    t.decimal "estimated_cost", precision: 10, scale: 2
    t.decimal "estimated_subsidy", precision: 10, scale: 2
    t.integer "response_set_id"
    t.integer "account_id"
    t.datetime "dispute_at"
    t.integer "dispute_by_id"
    t.string "dispute_reason", limit: 200
    t.datetime "dispute_resolved_at"
    t.string "dispute_resolved_reason", limit: 200
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "order_status_id"
    t.string "state", limit: 50
    t.integer "group_id"
    t.integer "bundle_product_id"
    t.datetime "fulfilled_at"
    t.datetime "reviewed_at"
    t.integer "statement_id"
    t.integer "journal_id"
    t.string "reconciled_note"
    t.integer "created_by", null: false
    t.integer "product_accessory_id"
    t.boolean "problem", default: false, null: false
    t.datetime "reconciled_at"
    t.integer "project_id"
    t.text "note"
    t.datetime "canceled_at"
    t.integer "canceled_by"
    t.string "canceled_reason"
    t.string "price_change_reason"
    t.integer "price_changed_by_user_id"
    t.string "problem_description_key_was"
    t.datetime "problem_resolved_at"
    t.integer "problem_resolved_by_id"
    t.datetime "ordered_at"
    t.index ["account_id"], name: "fk_od_accounts"
    t.index ["assigned_user_id"], name: "index_order_details_on_assigned_user_id"
    t.index ["bundle_product_id"], name: "fk_bundle_prod_id"
    t.index ["dispute_by_id"], name: "fk_rails_14de4f1c86"
    t.index ["group_id"], name: "index_order_details_on_group_id"
    t.index ["journal_id"], name: "index_order_details_on_journal_id"
    t.index ["order_id"], name: "fk_rails_e5976611fd"
    t.index ["order_status_id"], name: "index_order_details_on_order_status_id"
    t.index ["parent_order_detail_id"], name: "fk_rails_cc2adae8c3"
    t.index ["price_changed_by_user_id"], name: "index_order_details_on_price_changed_by_user_id"
    t.index ["price_policy_id"], name: "fk_rails_555b721183"
    t.index ["problem"], name: "index_order_details_on_problem"
    t.index ["problem_resolved_by_id"], name: "index_order_details_on_problem_resolved_by_id"
    t.index ["product_accessory_id"], name: "fk_rails_e4f0ef56a6"
    t.index ["product_id"], name: "fk_rails_4f2ac9473b"
    t.index ["project_id"], name: "index_order_details_on_project_id"
    t.index ["response_set_id"], name: "index_order_details_on_response_set_id"
    t.index ["state"], name: "index_order_details_on_state"
    t.index ["statement_id"], name: "index_order_details_on_statement_id"
  end

  create_table "order_imports", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id"
    t.integer "upload_file_id", null: false
    t.integer "error_file_id"
    t.boolean "fail_on_error", default: true
    t.boolean "send_receipts", default: false
    t.integer "created_by", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "index_order_imports_on_created_by"
    t.index ["error_file_id"], name: "index_order_imports_on_error_file_id"
    t.index ["facility_id"], name: "i_order_imports_facility_id"
    t.index ["upload_file_id"], name: "index_order_imports_on_upload_file_id"
  end

  create_table "order_statuses", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.integer "facility_id"
    t.integer "parent_id"
    t.integer "lft"
    t.integer "rgt"
    t.index ["facility_id", "parent_id", "name"], name: "index_order_statuses_on_facility_id_and_parent_id_and_name", unique: true
    t.index ["parent_id"], name: "index_order_statuses_on_parent_id"
  end

  create_table "orders", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "account_id"
    t.integer "user_id", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "facility_id"
    t.string "state", limit: 50
    t.integer "merge_with_order_id"
    t.integer "order_import_id"
    t.index ["account_id"], name: "fk_rails_144e25bef6"
    t.index ["facility_id"], name: "index_orders_on_facility_id"
    t.index ["merge_with_order_id"], name: "index_orders_on_merge_with_order_id"
    t.index ["order_import_id"], name: "index_orders_on_order_import_id"
    t.index ["state"], name: "index_orders_on_state"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "payments", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "account_id", null: false
    t.integer "statement_id"
    t.string "source", null: false
    t.string "source_id"
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.integer "paid_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "processing_fee", precision: 10, scale: 2, default: "0.0", null: false
    t.index ["account_id"], name: "index_payments_on_account_id"
    t.index ["paid_by_id"], name: "index_payments_on_paid_by_id"
    t.index ["statement_id"], name: "index_payments_on_statement_id"
  end

  create_table "price_group_members", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", limit: 50, null: false
    t.integer "price_group_id", null: false
    t.integer "user_id"
    t.integer "account_id"
    t.index ["account_id"], name: "index_price_group_members_on_account_id"
    t.index ["price_group_id"], name: "fk_rails_0425013e5b"
    t.index ["user_id"], name: "index_price_group_members_on_user_id"
  end

  create_table "price_group_products", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "price_group_id", null: false
    t.integer "product_id", null: false
    t.integer "reservation_window"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["price_group_id"], name: "index_price_group_products_on_price_group_id"
    t.index ["product_id"], name: "index_price_group_products_on_product_id"
  end

  create_table "price_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id"
    t.string "name", limit: 50, null: false
    t.integer "display_order", null: false
    t.boolean "is_internal", null: false
    t.boolean "admin_editable", default: true, null: false
    t.index ["facility_id", "name"], name: "index_price_groups_on_facility_id_and_name", unique: true
  end

  create_table "price_policies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", limit: 50, null: false
    t.integer "product_id"
    t.integer "price_group_id", null: false
    t.boolean "can_purchase", default: false, null: false
    t.datetime "start_date", null: false
    t.decimal "unit_cost", precision: 10, scale: 2
    t.decimal "unit_subsidy", precision: 10, scale: 2
    t.decimal "usage_rate", precision: 12, scale: 4
    t.decimal "minimum_cost", precision: 10, scale: 2
    t.decimal "cancellation_cost", precision: 10, scale: 2
    t.decimal "usage_subsidy", precision: 12, scale: 4
    t.datetime "expire_date", null: false
    t.string "charge_for"
    t.string "legacy_rates"
    t.boolean "full_price_cancellation", default: false, null: false
    t.string "note", limit: 256
    t.integer "created_by_id"
    t.index ["created_by_id"], name: "index_price_policies_on_created_by_id"
    t.index ["price_group_id"], name: "fk_rails_74aa223960"
    t.index ["product_id"], name: "index_price_policies_on_product_id"
  end

  create_table "product_access_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_access_groups_on_product_id"
  end

  create_table "product_access_schedule_rules", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_access_group_id", null: false
    t.integer "schedule_rule_id", null: false
    t.index ["product_access_group_id"], name: "index_product_access_schedule_rules_on_product_access_group_id"
    t.index ["schedule_rule_id"], name: "index_product_access_schedule_rules_on_schedule_rule_id"
  end

  create_table "product_accessories", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "accessory_id", null: false
    t.string "scaling_type", default: "quantity", null: false
    t.datetime "deleted_at"
    t.index ["accessory_id"], name: "index_product_accessories_on_accessory_id"
    t.index ["product_id"], name: "index_product_accessories_on_product_id"
  end

  create_table "product_users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.integer "approved_by", null: false
    t.datetime "approved_at", null: false
    t.integer "product_access_group_id"
    t.datetime "requested_at"
    t.index ["product_access_group_id"], name: "index_product_users_on_product_access_group_id"
    t.index ["product_id"], name: "fk_products"
    t.index ["user_id"], name: "index_product_users_on_user_id"
  end

  create_table "products", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "type", limit: 50, null: false
    t.integer "facility_id", null: false
    t.string "name", limit: 200, null: false
    t.string "url_name", limit: 50, null: false
    t.text "description"
    t.integer "schedule_id"
    t.boolean "requires_approval", default: false, null: false
    t.boolean "allows_training_requests", default: true, null: false
    t.integer "initial_order_status_id"
    t.boolean "is_archived", default: false, null: false
    t.boolean "is_hidden", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "min_reserve_mins"
    t.integer "max_reserve_mins"
    t.integer "min_cancel_hours"
    t.integer "facility_account_id"
    t.string "account"
    t.boolean "show_details", default: false, null: false
    t.integer "auto_cancel_mins"
    t.string "contact_email"
    t.integer "reserve_interval"
    t.integer "lock_window", default: 0, null: false
    t.text "training_request_contacts"
    t.integer "cutoff_hours", default: 0, null: false
    t.string "dashboard_token"
    t.string "user_notes_field_mode", default: "hidden", null: false
    t.string "user_notes_label"
    t.string "order_notification_recipient"
    t.text "cancellation_email_recipients"
    t.text "issue_report_recipients"
    t.boolean "email_purchasers_on_order_status_changes", default: false, null: false
    t.boolean "problems_resolvable_by_user", default: false, null: false
    t.index ["dashboard_token"], name: "index_products_on_dashboard_token"
    t.index ["facility_account_id"], name: "fk_facility_accounts"
    t.index ["facility_id"], name: "fk_rails_0c9fa1afbe"
    t.index ["initial_order_status_id"], name: "index_products_on_initial_order_status_id"
    t.index ["schedule_id"], name: "i_instruments_schedule_id"
    t.index ["type", "is_archived", "schedule_id"], name: "index_products_on_type_and_is_archived_and_schedule_id"
    t.index ["url_name"], name: "index_products_on_url_name"
  end

  create_table "projects", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "facility_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: true, null: false
    t.index ["facility_id", "name"], name: "index_projects_on_facility_id_and_name", unique: true
    t.index ["facility_id"], name: "index_projects_on_facility_id"
  end

  create_table "relays", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "instrument_id"
    t.string "ip", limit: 15
    t.integer "outlet"
    t.string "username", limit: 50
    t.string "password", limit: 50
    t.boolean "auto_logout"
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "auto_logout_minutes", default: 60
    t.integer "ip_port"
    t.index ["instrument_id"], name: "index_relays_on_instrument_id"
  end

  create_table "reservations", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "order_detail_id"
    t.integer "product_id", null: false
    t.datetime "reserve_start_at", null: false
    t.datetime "reserve_end_at"
    t.datetime "actual_start_at"
    t.datetime "actual_end_at"
    t.string "admin_note"
    t.string "type"
    t.string "category"
    t.integer "expires_mins_before"
    t.integer "created_by_id"
    t.datetime "deleted_at"
    t.string "group_id"
    t.string "user_note"
    t.integer "billable_minutes"
    t.index ["created_by_id"], name: "index_reservations_on_created_by_id"
    t.index ["deleted_at"], name: "index_reservations_on_deleted_at"
    t.index ["group_id"], name: "index_reservations_on_group_id"
    t.index ["order_detail_id"], name: "res_od_uniq_fk", unique: true
    t.index ["product_id", "reserve_start_at"], name: "index_reservations_on_product_id_and_reserve_start_at"
    t.index ["type", "deleted_at", "product_id", "reserve_start_at", "reserve_end_at"], name: "reservations_for_timeline"
  end

  create_table "sanger_seq_product_groups", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "group", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["product_id"], name: "index_sanger_seq_product_groups_on_product_id", unique: true
  end

  create_table "sanger_sequencing_batches", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "created_by_id"
    t.text "well_plates_raw"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "facility_id"
    t.string "group"
    t.index ["created_by_id"], name: "index_sanger_sequencing_batches_on_created_by_id"
    t.index ["facility_id"], name: "index_sanger_sequencing_batches_on_facility_id"
    t.index ["group"], name: "index_sanger_sequencing_batches_on_group"
  end

  create_table "sanger_sequencing_samples", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "submission_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "customer_sample_id"
    t.index ["submission_id"], name: "index_sanger_sequencing_samples_on_submission_id"
  end

  create_table "sanger_sequencing_submissions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "order_detail_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "batch_id"
    t.index ["batch_id"], name: "fk_rails_24eeb2c9b4"
    t.index ["order_detail_id"], name: "index_sanger_sequencing_submissions_on_order_detail_id"
  end

  create_table "schedule_rules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.decimal "discount_percent", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "start_hour", null: false
    t.integer "start_min", null: false
    t.integer "end_hour", null: false
    t.integer "end_min", null: false
    t.boolean "on_sun", null: false
    t.boolean "on_mon", null: false
    t.boolean "on_tue", null: false
    t.boolean "on_wed", null: false
    t.boolean "on_thu", null: false
    t.boolean "on_fri", null: false
    t.boolean "on_sat", null: false
    t.index ["product_id"], name: "index_schedule_rules_on_product_id"
  end

  create_table "schedules", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.integer "facility_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["facility_id"], name: "i_schedules_facility_id"
  end

  create_table "secure_rooms_alarm_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "additional_data"
    t.string "class_code"
    t.string "event_code"
    t.string "event_description"
    t.string "mac_address"
    t.string "message_id"
    t.datetime "message_time"
    t.string "message_type"
    t.string "priority"
    t.string "task_code"
    t.string "task_description"
    t.text "raw_post"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "secure_rooms_card_readers", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.string "card_reader_number"
    t.string "control_device_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "description"
    t.boolean "direction_in", default: true, null: false
    t.string "tablet_token"
    t.index ["card_reader_number", "control_device_number"], name: "i_secure_room_reader_ids", unique: true
    t.index ["product_id"], name: "index_secure_rooms_card_readers_on_product_id"
    t.index ["tablet_token"], name: "index_secure_rooms_card_readers_on_tablet_token", unique: true
  end

  create_table "secure_rooms_events", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "card_reader_id", null: false
    t.integer "user_id"
    t.datetime "occurred_at"
    t.string "outcome"
    t.string "outcome_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_id"
    t.string "card_number", null: false
    t.index ["account_id"], name: "index_secure_rooms_events_on_account_id"
    t.index ["card_reader_id"], name: "index_secure_rooms_events_on_card_reader_id"
    t.index ["user_id"], name: "index_secure_rooms_events_on_user_id"
  end

  create_table "secure_rooms_occupancies", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "product_id", null: false
    t.integer "user_id", null: false
    t.integer "account_id"
    t.integer "entry_event_id"
    t.datetime "entry_at"
    t.integer "exit_event_id"
    t.datetime "exit_at"
    t.datetime "orphaned_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "order_detail_id"
    t.index ["account_id"], name: "index_secure_rooms_occupancies_on_account_id"
    t.index ["entry_event_id"], name: "index_secure_rooms_occupancies_on_entry_event_id"
    t.index ["exit_event_id"], name: "index_secure_rooms_occupancies_on_exit_event_id"
    t.index ["order_detail_id"], name: "index_secure_rooms_occupancies_on_order_detail_id"
    t.index ["product_id"], name: "index_secure_rooms_occupancies_on_product_id"
    t.index ["user_id"], name: "index_secure_rooms_occupancies_on_user_id"
  end

  create_table "splits", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "parent_split_account_id", null: false
    t.integer "subaccount_id", null: false
    t.decimal "percent", precision: 6, scale: 3, null: false
    t.boolean "apply_remainder", null: false
    t.index ["parent_split_account_id"], name: "index_splits_on_parent_split_account_id"
    t.index ["subaccount_id"], name: "index_splits_on_subaccount_id"
  end

  create_table "statement_rows", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "statement_id", null: false
    t.integer "order_detail_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_detail_id"], name: "index_statement_rows_on_order_detail_id"
    t.index ["statement_id"], name: "index_statement_rows_on_statement_id"
  end

  create_table "statements", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "facility_id", null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.integer "account_id", null: false
    t.index ["account_id"], name: "index_statements_on_account_id"
    t.index ["facility_id"], name: "fk_statement_facilities"
  end

  create_table "stored_files", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "order_detail_id"
    t.integer "product_id"
    t.string "name", limit: 200, null: false
    t.string "file_type", limit: 50, null: false
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.string "file_file_name"
    t.string "file_content_type"
    t.integer "file_file_size"
    t.datetime "file_updated_at"
    t.index ["order_detail_id"], name: "fk_files_od"
    t.index ["product_id"], name: "fk_files_product"
  end

  create_table "training_requests", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.integer "product_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_training_requests_on_product_id"
    t.index ["user_id"], name: "index_training_requests_on_user_id"
  end

  create_table "user_preferences", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id"
    t.string "name", null: false
    t.string "value", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_user_preferences_on_user_id_and_name", unique: true
  end

  create_table "user_roles", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "facility_id"
    t.string "role", null: false
    t.index ["facility_id"], name: "fk_rails_dca27403dd"
    t.index ["user_id", "facility_id", "role"], name: "index_user_roles_on_user_id_and_facility_id_and_role"
  end

  create_table "users", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "username", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "email", default: "", null: false
    t.string "encrypted_password"
    t.string "password_salt"
    t.integer "sign_in_count", default: 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.integer "uid"
    t.datetime "suspended_at"
    t.string "suspension_note"
    t.string "card_number"
    t.datetime "expired_at"
    t.string "expired_note"
    t.index ["card_number"], name: "index_users_on_card_number"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["expired_at"], name: "index_users_on_expired_at"
    t.index ["uid"], name: "index_users_on_uid"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "vestal_versions", id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "versioned_id"
    t.string "versioned_type"
    t.integer "user_id"
    t.string "user_type"
    t.string "user_name"
    t.text "modifications"
    t.integer "version_number"
    t.string "tag"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reason_for_update"
    t.integer "reverted_from"
    t.string "commit_label"
    t.index ["commit_label"], name: "index_vestal_versions_on_commit_label"
    t.index ["created_at"], name: "index_vestal_versions_on_created_at"
    t.index ["tag"], name: "index_vestal_versions_on_tag"
    t.index ["user_id", "user_type"], name: "index_vestal_versions_on_user_id_and_user_type"
    t.index ["user_name"], name: "index_vestal_versions_on_user_name"
    t.index ["version_number"], name: "index_vestal_versions_on_version_number"
    t.index ["versioned_id", "versioned_type"], name: "index_vestal_versions_on_versioned_id_and_versioned_type"
  end

  add_foreign_key "account_facility_joins", "accounts"
  add_foreign_key "account_facility_joins", "facilities"
  add_foreign_key "account_users", "accounts", name: "fk_accounts"
  add_foreign_key "account_users", "users"
  add_foreign_key "accounts", "facilities", name: "fk_account_facility_id"
  add_foreign_key "bulk_email_jobs", "facilities"
  add_foreign_key "bulk_email_jobs", "users"
  add_foreign_key "bundle_products", "products", column: "bundle_product_id", name: "fk_bundle_prod_prod"
  add_foreign_key "bundle_products", "products", name: "fk_bundle_prod_bundle"
  add_foreign_key "email_events", "users"
  add_foreign_key "facility_accounts", "facilities", name: "fk_facilities"
  add_foreign_key "instrument_statuses", "products", column: "instrument_id", name: "fk_int_stats_product"
  add_foreign_key "journal_rows", "accounts"
  add_foreign_key "journal_rows", "journals"
  add_foreign_key "journal_rows", "order_details"
  add_foreign_key "log_events", "users"
  add_foreign_key "nu_product_cert_requirements", "nu_safety_certificates"
  add_foreign_key "nu_product_cert_requirements", "products"
  add_foreign_key "nu_safety_certificates", "users", column: "deleted_by_id"
  add_foreign_key "order_details", "accounts", name: "fk_od_accounts"
  add_foreign_key "order_details", "journals"
  add_foreign_key "order_details", "order_details", column: "parent_order_detail_id"
  add_foreign_key "order_details", "order_statuses"
  add_foreign_key "order_details", "orders"
  add_foreign_key "order_details", "price_policies"
  add_foreign_key "order_details", "product_accessories"
  add_foreign_key "order_details", "products"
  add_foreign_key "order_details", "products", column: "bundle_product_id", name: "fk_bundle_prod_id"
  add_foreign_key "order_details", "statements"
  add_foreign_key "order_details", "users", column: "assigned_user_id"
  add_foreign_key "order_details", "users", column: "dispute_by_id"
  add_foreign_key "order_details", "users", column: "price_changed_by_user_id"
  add_foreign_key "order_details", "users", column: "problem_resolved_by_id"
  add_foreign_key "order_imports", "facilities", name: "fk_order_imports_facilities"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "facilities"
  add_foreign_key "orders", "order_imports"
  add_foreign_key "orders", "orders", column: "merge_with_order_id"
  add_foreign_key "orders", "users"
  add_foreign_key "payments", "accounts"
  add_foreign_key "payments", "statements"
  add_foreign_key "payments", "users", column: "paid_by_id"
  add_foreign_key "price_group_members", "accounts"
  add_foreign_key "price_group_members", "price_groups"
  add_foreign_key "price_group_members", "users"
  add_foreign_key "price_groups", "facilities"
  add_foreign_key "price_policies", "price_groups"
  add_foreign_key "price_policies", "users", column: "created_by_id"
  add_foreign_key "product_users", "products", name: "fk_products"
  add_foreign_key "product_users", "users"
  add_foreign_key "products", "facilities"
  add_foreign_key "products", "facility_accounts", name: "fk_facility_accounts"
  add_foreign_key "products", "schedules", name: "fk_instruments_schedule"
  add_foreign_key "projects", "facilities"
  add_foreign_key "reservations", "order_details"
  add_foreign_key "reservations", "products", name: "reservations_instrument_id_fk"
  add_foreign_key "reservations", "users", column: "created_by_id"
  add_foreign_key "sanger_seq_product_groups", "products"
  add_foreign_key "sanger_sequencing_batches", "facilities"
  add_foreign_key "sanger_sequencing_samples", "sanger_sequencing_submissions", column: "submission_id", on_delete: :cascade
  add_foreign_key "sanger_sequencing_submissions", "sanger_sequencing_batches", column: "batch_id", on_delete: :nullify
  add_foreign_key "schedule_rules", "products"
  add_foreign_key "schedules", "facilities", name: "fk_schedules_facility"
  add_foreign_key "secure_rooms_card_readers", "products"
  add_foreign_key "secure_rooms_events", "accounts"
  add_foreign_key "secure_rooms_occupancies", "accounts"
  add_foreign_key "secure_rooms_occupancies", "order_details"
  add_foreign_key "secure_rooms_occupancies", "products"
  add_foreign_key "secure_rooms_occupancies", "secure_rooms_events", column: "entry_event_id"
  add_foreign_key "secure_rooms_occupancies", "secure_rooms_events", column: "exit_event_id"
  add_foreign_key "secure_rooms_occupancies", "users"
  add_foreign_key "statement_rows", "order_details"
  add_foreign_key "statement_rows", "statements"
  add_foreign_key "statements", "accounts"
  add_foreign_key "statements", "facilities", name: "fk_statement_facilities"
  add_foreign_key "stored_files", "order_details", name: "fk_files_od"
  add_foreign_key "stored_files", "products", name: "fk_files_product"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_roles", "facilities"
  add_foreign_key "user_roles", "users"
end
