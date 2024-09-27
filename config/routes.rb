Rails.application.routes.draw do
  devise_for :users, path: "auth"

  resources :challenges do
    collection do
      get :import_form
      post :import
      get :export
    end
  end
  resources :users

  get "scoring", to: "scoring#index"
  get "scoring/:id", to: "scoring#score", as: :scoring_score
  post "scoring/update"

  resources :group_permissions, only: [ :index, :update ]

  resources :settings, only: [ :index ] do
    patch :update, on: :collection
  end

  get "home/index"
  root "home#index" # Special case that sets this to the home page.

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  mount ActionCable.server => "/cable"

  # Defines the root path route ("/")
  # root "posts#index"

  # Allows user to sign out through a GET request
  devise_scope :user do
    get "/users/sign_out" => "devise/sessions#destroy"
  end
end
