# frozen_string_literal: true

require "facility_product_routing_concern"

Rails.application.routes.draw do
  get "/users/sign_in.pdf" => redirect("/users/sign_in")
  devise_for :users
  mount SangerSequencing::Engine => "/" if defined?(SangerSequencing)

  if SettingsHelper.feature_on?(:password_update)
    match "/users/password/edit_current", to: "user_password#edit_current", as: "edit_current_password", via: [:get, :post]
    match "/users/password/reset", to: "user_password#reset", as: "reset_password", via: [:get, :post]
  end

  # root route
  root to: "public#index"

  # authentication
  get "switch_back", to: "public#switch_back"

  # shared searches
  get "/user_search_results", to: "search#user_search_results"
  get "/#{I18n.t('facilities_downcase')}/:facility_id/price_group/:price_group_id/account_price_group_members/search_results", to: "account_price_group_members#search_results"

  post "global_search" => "global_search#index", as: "global_search"

  resources :users, only: [] do
    resources :user_preferences, only: [:index, :edit, :update], shallow: true
  end

  # front-end accounts
  resources :accounts, only: [:index, :show] do
    resources :statements, only: [:show, :index]
    member do
      get "user_search"
    end

    if SettingsHelper.feature_on? :suspend_accounts
      get "suspend", to: "accounts#suspend", as: "suspend"
      get "unsuspend", to: "accounts#unsuspend", as: "unsuspend"
    end

    resources :account_users, only: [:new, :destroy, :create, :index] do
      collection do
        get "user_search"
      end
    end

    resources :facilities, only: [], path: I18n.t("facilities_downcase") do
      resources :statements, only: [:show]
    end
  end

  resources :facilities, except: [:delete], path: I18n.t("facilities_downcase") do
    collection do
      get "list"
    end

    member do
      get "manage"
      get "dashboard"
    end

    resources :products, only: [:index] do
      resources :product_accessories, only: [:index, :create, :destroy], path: "accessories"
      resources :training_requests, only: [:new, :create] if SettingsHelper.feature_on?(:training_requests)

      resource :product_notification, only: [:show, :edit, :update], path: "notifications", as: "notifications"
      resources :product_research_safety_certification_requirements, only: [:index, :create, :destroy], path: "certification_requirements"
    end

    resources :product_display_groups do
      collection do
        resource :product_display_group_positions, only: [:edit, :update], path: "positions"
      end
    end

    resource "instrument_schedule_position", only: [:edit, :update, :show]

    get "instrument_statuses", to: "instruments#instrument_statuses", as: "instrument_statuses"

    resources :training_requests, only: [:index, :destroy] if SettingsHelper.feature_on?(:training_requests)

    resources :instruments do
      get :dashboard, to: "instruments_dashboard#dashboard", on: :collection
      get :public_dashboard, to: "instruments_dashboard#public_dashboard", on: :collection

      resources :single_reservations, only: [:new, :create]

      collection do
        get "list", to: "instruments#public_list"
      end
      facility_product_routing_concern
      get "public_schedule", to: "instruments#public_schedule"
      get "schedule",        to: "instruments#schedule"
      get "switch",          to: "instruments#switch"
      resources :issues, only: [:new, :create], controller: "instrument_issues"

      put "bring_online", to: "offline_reservations#bring_online"
      resources :offline_reservations, only: [:new, :create, :edit, :update]

      resources :schedule_rules, except: [:show]
      resources :product_access_groups
      resources :price_policies, controller: "instrument_price_policies", except: [:show]
      resources :reservations, only: [:new, :create, :destroy], controller: "facility_reservations" do
        get "edit_admin", to: "facility_reservations#edit_admin"
        patch "update_admin", to: "facility_reservations#update_admin"
      end

      resources :reservations, only: [:index]
      put "update_restrictions", to: "product_users#update_restrictions"

      resource :alert, controller: "instrument_alerts", only: [:new, :create, :destroy]
    end

    resource :relays_activation, only: [:create, :destroy]

    resources :services do
      facility_product_routing_concern
      resources :price_policies, controller: "service_price_policies", except: [:show]
    end

    resources :timed_services do
      facility_product_routing_concern
      resources :price_policies, controller: "timed_service_price_policies", except: [:show]
    end

    resources :items do
      facility_product_routing_concern
      resources :price_policies, controller: "item_price_policies", except: [:show]
    end

    resources :bundles do
      get :manage, on: :member
      resources :bundle_products, controller: "bundle_products", except: [:show]
      resources :file_uploads, path: "files", only: [:index, :create, :destroy]
      get "/files/:file_type/:id", to: "file_uploads#download", as: "download_product_file"
    end

    resources :price_group_products, only: [:edit, :update]

    resources :order_statuses, except: [:show]

    resources :facility_users, controller: "facility_users", only: [:index, :destroy], path: "#{I18n.t('facility_downcase')}_users" do
      collection do
        get "search"
      end
      match "map_user", to: "facility_users#map_user", via: [:get, :post]
    end

    users_options = if SettingsHelper.feature_on?(:create_users)
                      {}
                    else
                      { except: [:edit, :update, :new, :create], constraints: { id: /\d+/ } }
                    end

    resources :users, users_options do
      if SettingsHelper.feature_on?(:create_users)
        collection do
          get "new_external"
          post "search"
        end
        patch "unexpire", on: :member
        resource :suspension, controller: :user_suspension, only: [:create, :destroy]
      end

      get "switch_to",    to: "users#switch_to"
      get "orders",       to: "users#orders"
      resources :reservations, only: [:index], param: :order_detail_id, controller: "facility_user_reservations" do
        member do
          put "cancel"
        end
      end
      get "access_list",  to: "users#access_list"
      post "access_list/approvals", to: "users#access_list_approvals"

      resource :accounts, controller: "user_accounts", only: [:show, :edit, :update]
      resources :clone_account_memberships, only: %i[index new create] do
        get :search, on: :collection
      end
      resources :user_research_safety_certifications, only: [:index]
    end

    resources :facility_accounts,
              controller: "facility_facility_accounts",
              only: [:index, :new, :create, :edit, :update], path: "#{I18n.t('facility_downcase')}_accounts"

    resources :orders, controller: "facility_orders", only: [:index, :update, :show] do
      member do
        post "send_receipt"
      end

      collection do
        post "assign_price_policies_to_problem_orders"
        post "batch_update"
        get "show_problems"
        get "tab_counts"
      end

      resources :order_details, controller: "facility_order_details", only: [:show, :destroy] do
        resources :reservations, controller: "facility_reservations", only: [:edit, :update, :show]
        resources :accessories, only: [:new, :create]
        resource :reconcilliation, only: [:destroy]
        member do
          get "manage", to: "order_management/order_details#edit"
          patch "manage", to: "order_management/order_details#update"
          put "manage", to: "order_management/order_details#update"
          get "pricing", to: "order_management/order_details#pricing"
          get "files", to: "order_management/order_details#files"
          post "remove_from_journal", to: "order_management/order_details#remove_from_journal"
          get "sample_results/:stored_file_id", to: "order_management/order_details#sample_results", as: "sample_results"
          get "template_results/:stored_file_id", to: "order_management/order_details#template_results", as: "template_results"
        end
      end
    end

    resources :order_imports, only: [:new, :create] do
      get "error_report", to: "order_imports#error_report", on: :member
    end

    resources :reservations, controller: "facility_reservations", only: :index do
      collection do
        post "assign_price_policies_to_problem_orders"
        post "batch_update"
        get "show_problems"
        get "timeline"
        get "tab_counts"
      end
    end

    get "public_timeline", to: "reservations#public_timeline", as: "public_timeline" if SettingsHelper.feature_on?(:daily_view)

    ### Feature Toggle Editing Accounts ###
    if SettingsHelper.feature_on?(:edit_accounts)
      resources :accounts, controller: "facility_accounts", only: [:new, :create, :edit, :update] do
        collection do
          get "new_account_user_search"
        end
        resources :account_users, controller: "facility_account_users", only: [:new, :destroy, :create, :update] do
          collection do
            get "user_search"
          end
        end

        resource :account_facility_joins, only: [:edit, :update], path: "facilities" if SettingsHelper.feature_on?(:multi_facility_accounts)
      end
    end

    resources :accounts, controller: "facility_accounts", only: [:index, :show] do
      get "search_results", via: [:post], on: :collection

      if SettingsHelper.feature_on?(:suspend_accounts)
        get "suspend",   to: "facility_accounts#suspend",   as: "suspend"
        get "unsuspend", to: "facility_accounts#unsuspend", as: "unsuspend"
      end

      get "/members", to: "facility_accounts#members", as: "members"

      if Account.config.statements_enabled?
        get "/statements", to: "facility_accounts#statements", as: :statements
        get "/statements/:statement_id", to: "facility_accounts#show_statement", as: :statement
      end

      # Dynamically add routes like credit_cards and purchase_orders
      Account.config.reconcilable_account_types.each do |type|
        plural_name = Account.config.account_type_to_route(type)
        get plural_name, to: "facility_accounts_reconciliation#index", on: :collection, account_type: type
        post "update_#{plural_name}", to: "facility_accounts_reconciliation#update", on: :collection, account_type: type
      end

      resources :orders, controller: "facility_account_orders", only: [:index]
    end

    ######

    resources :journals, controller: "facility_journals", only: [:index, :new, :create, :update, :show] do
      post "reconcile", to: "facility_journals#reconcile"
    end

    resources :price_groups do
      member do
        get "users"
        get "accounts"
      end

      resources :user_price_group_members, only: [:new, :destroy, :create]

      resources :account_price_group_members, only: [:new, :destroy, :create]
    end

    get "disputed_orders", to: "facilities#disputed_orders"
    get "notifications",       to: "facility_notifications#index"
    post "notifications/send", to: "facility_notifications#send_notifications", as: "send_notifications"
    get "transactions",        to: "facilities#transactions"
    get "in_review",           to: "facility_notifications#in_review",          as: "notifications_in_review"
    post "in_review/mark",     to: "facility_notifications#mark_as_reviewed",   as: "notifications_mark_as_reviewed"
    get "movable_transactions", to: "facilities#movable_transactions"
    post "movable_transactions/reassign_chart_strings", to: "facilities#reassign_chart_strings"
    post "movable_transactions/confirm", to: "facilities#confirm_transactions"
    post "movable_transactions/move", to: "facilities#move_transactions"

    resources :statements, controller: "facility_statements", only: [:index, :new, :show, :create]

    get "general_reports/raw", to: "reports/export_raw_reports#export_all", as: "export_raw_reports"
    get "general_reports/:report_by", to: "reports/general_reports#index", as: "general_reports"
    get "instrument_reports/:report_by", to: "reports/instrument_reports#index", as: "instrument_reports"
    get "instrument_unavailable_reports/raw",
        to: "reports/instrument_unavailable_export_raw_reports#export_all",
        as: "instrument_unavailable_export_raw_reports"
    get "instrument_unavailable_reports/:report_by",
        to: "reports/instrument_unavailable_reports#index",
        as: "instrument_unavailable_reports"
    get "instrument_day_reports/:report_by", to: "reports/instrument_day_reports#index", as: "instrument_day_reports"
  end

  # global settings
  resources :affiliates, except: :show
  resources :journal_cutoff_dates
  resources :global_user_roles do
    get "search", on: :collection
  end
  resources :log_events, only: :index
  resources :research_safety_certificates, except: :show

  # order process
  get "/orders/cart", to: "orders#cart", as: "cart"
  get "/orders(\/:status)", to: "orders#index", as: "orders_status", constraints: { status: /pending|all/ } ## emacs quoting \/

  put "/orders/:id/remove/:order_detail_id", to: "orders#remove", as: "remove_order"
  get "/order/:id/add_account", to: "orders#add_account", as: "add_account"

  resources :orders do
    member do
      get "add"
      put "add"
      get "purchase"
      put "purchase"
      match "choose_account", via: [:get, :post]
      get "update_or_purchase"
      patch "update_or_purchase"
      put "update_or_purchase"
      get "receipt"
      put "clear"
    end

    resources :order_details, only: [:show, :edit, :update] do
      put :cancel, on: :member
      put :dispute, on: :member
      get :order_file, controller: "order_detail_stored_files"
      post :upload_order_file, controller: "order_detail_stored_files"
      get :remove_order_file, controller: "order_detail_stored_files"

      get :sample_results, to: "order_detail_stored_files#sample_results_zip", as: "sample_results_zip"
      get "sample_results/:id", to: "order_detail_stored_files#sample_results", as: "sample_results"
      get "template_results/:id", to: "order_detail_stored_files#template_results", as: "template_results"

      resources :reservations, except: [:index] do
        get "/move",               to: "reservations#earliest_move_possible"
        post "/move",              to: "reservations#move",              as: "move_reservation"
        get "/switch_instrument",  to: "reservations#switch_instrument", as: "switch_instrument"
      end

      resources :accessories, only: [:new, :create]
    end
  end

  resources :problem_reservations, only: [:edit, :update]

  # notifications
  resources :notifications, only: [:index] do
    collection do
      get :count
    end
  end

  resources :transactions, only: [:index] do
    collection do
      get :in_review
      post :mark_as_reviewed
    end
  end

  # reservations
  get "reservations", to: "reservations#list", as: "reservations"
  get "reservations(/:status)", to: "reservations#list", as: "reservations_status"

  resources :my_files, only: [:index] if SettingsHelper.feature_on?(:my_files)

  # file upload routes
  post  "/#{I18n.t('facilities_downcase')}/:facility_id/:product/:product_id/sample_results", to: "file_uploads#upload_sample_results", as: "add_uploader_file"
  get   "/#{I18n.t('facilities_downcase')}/:facility_id/:product/:product_id/files/product_survey", to: "file_uploads#product_survey", as: "product_survey"
  post  "/#{I18n.t('facilities_downcase')}/:facility_id/:product/:product_id/files/create_product_survey", to: "file_uploads#create_product_survey", as: "create_product_survey"

  put   "/#{I18n.t('facilities_downcase')}/:facility_id/services/:service_id/surveys/:external_service_passer_id/activate",   to: "surveys#activate",                 as: "activate_survey"
  put   "/#{I18n.t('facilities_downcase')}/:facility_id/services/:service_id/surveys/:external_service_passer_id/deactivate", to: "surveys#deactivate",               as: "deactivate_survey"
  get "/#{I18n.t('facilities_downcase')}/:facility_id/services/:service_id/surveys/:external_service_id/complete", to: "surveys#complete", as: "complete_survey"

  namespace :admin do
    namespace :services do
      post "process_one_minute_tasks"
      post "process_five_minute_tasks"
    end
  end

  # api
  namespace :api do
    resources :order_details, only: [:show, :index]
  end

  namespace :formio do
    resource :submission, only: [:new, :show, :edit]
  end

  # See config/initializers/health_check.rb for more information
  health_check_routes
end
