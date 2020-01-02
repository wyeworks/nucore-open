# frozen_string_literal: true

Rails.application.routes.draw do
  resources :certificates, except: :show, controller: "nu_research_safety/certificates"

  resources :facilities, except: [], path: I18n.t("facilities_downcase") do
    resources :products, only: [] do
      resources :product_certification_requirements, only: [:index, :create, :destroy],
                                                     path: "certification_requirements",
                                                     controller: "nu_research_safety/product_certification_requirements"
    end
    resources :user, only: [] do
      resources :user_certificates, only: [:index], controller: "nu_research_safety/user_certificates"
    end
  end
end
