# frozen_string_literal: true

Rails.application.routes.draw do
  resources :facilities, only: [], path: I18n.t("facilities_downcase") do
    resources :secure_rooms, except: [:show] do
      facility_product_routing_concern
      resources :price_policies, controller: "secure_room_price_policies", except: :show
      resources :card_readers, controller: "secure_rooms/card_readers", except: :show
      resources :schedule_rules, except: [:show]
      resources :product_access_groups
      resources :occupancies, only: [:index], controller: "secure_rooms/occupancies" do
        collection do
          get "refresh"
        end
      end
      put "update_restrictions", to: "product_users#update_restrictions"

      resource :ethernet_port, controller: "secure_rooms/ethernet_ports", only: [:edit, :update]
    end

    resources :users, only: [] do
      get :"card_number/edit", to: "secure_rooms/card_numbers#edit"
      patch :"card_number/update", to: "secure_rooms/card_numbers#update"
    end

    resources :occupancies, controller: "secure_rooms/facility_occupancies", only: :index do
      collection do
        post "assign_price_policies_to_problem_orders"
        post "batch_update"
        post "send_problem_notifications"
        get "notification_count"
        get "show_problems"
        get "tab_counts"
        get "dashboard"
      end
    end
  end

  namespace :secure_rooms_api do
    post "/scan", to: "scans#scan"
    resources :events, only: :create
  end
end
