Rails.application.routes.draw do
  root "landing#show"
  get "up", to: "rails/health#show", as: :rails_health_check
  resource :session, only: %i[new create destroy]
  namespace :host do
    resources :tasting_sessions, param: :invite_token, only: %i[index new create show] do
      member do
        post :advance
        patch :lock
      end
      resources :rounds, param: :number, only: %i[create update destroy], controller: "rounds"
      resources :participants, param: :participant_token, only: :destroy
    end
  end
  get "tv/:tv_token", to: "tv#show", as: :tv
  get "join/:invite_token", to: "participations#new", as: :join
  post "join/:invite_token", to: "participations#create"
  get "tasting/:invite_token", to: "tasting_sessions#show", as: :tasting
  post "tasting/:invite_token/ratings", to: "ratings#create", as: :ratings
  get "tasting/:invite_token/export", to: "tasting_sessions#export", as: :export_tasting
  mount ActionCable.server => "/cable"
end
