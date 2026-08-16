Rails.application.routes.draw do
  root "controllers#index"

  resources :controllers, only: [ :index, :show, :new, :create, :destroy ] do
    # new: preview the merge, create: perform it, destroy: undo it.
    resource :merge, only: [ :new, :create, :destroy ], controller: "merges"

    member do
      post :sync
      post :backfill
      post :claim_zone_label
      get :manage
      get :history
      get :calendar
      get :day
    end
    collection do
      post :sync_account
    end
  end

  resources :zones, only: :show
  resources :zone_aliases, only: :destroy

  mount MissionControl::Jobs::Engine, at: "/jobs"

  get "up" => "rails/health#show", as: :rails_health_check
end
