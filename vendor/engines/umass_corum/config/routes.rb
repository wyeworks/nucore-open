# frozen_string_literal: true

Rails.application.routes.draw do
  get "facilities/:facility_id/umass_corum_voucher_splits_mivp_pending", to: "voucher_splits_reconciliation#pending", as: :voucher_splits_mivp_pending
  get "facilities/:facility_id/umass_corum_voucher_splits", to: "voucher_splits_reconciliation#index", as: :voucher_splits
  post "facilities/:facility_id/update_umass_corum_voucher_splits", to: "voucher_splits_reconciliation#update", as: :update_umass_corum_voucher_splits_facility_accounts

  resources :admin_reports, only: :index do
    collection do
      post "relay_data"
      post "user_data"
      post "account_user_data"
      post "facility_rates_data"
    end
  end
end
