# frozen_string_literal: true

module FacilityProductRoutingConcern

  def facility_product_routing_concern
    get :manage, on: :member
    resources :users, controller: "product_users", except: [:show, :edit, :create]
    resources :file_uploads, path: "files", only: [:index, :create, :destroy]
    get "/files/:file_type/:id", to: "file_uploads#download", as: "download_product_file"
  end

end

ActionDispatch::Routing::Mapper.include FacilityProductRoutingConcern
