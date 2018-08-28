# frozen_string_literal: true

# This engine should be mounted at "/" in order to support both the front-end
# /sanger_sequencing/submissions/new and the back end /facilities/xxx/sanger_sequencing/submissions
Rails.application.routes.draw do
  namespace :sanger_sequencing, path: I18n.t("sanger_sequencing.route") do
    resources :submissions, only: [:new, :show, :edit, :update] do
      get :fetch_ids, on: :member
    end
  end

  resources :facilities, only: [] do
    namespace :sanger_sequencing do
      namespace :admin do
        resources :submissions, only: [:index, :show]
        resources :batches, only: [:index, :show, :new, :create, :destroy] do
          get "well_plates/:well_plate_index", action: :well_plate, on: :member, as: :well_plate
          post :upload, on: :member
        end
      end
    end
  end
end
