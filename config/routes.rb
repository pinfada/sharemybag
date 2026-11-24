Rails.application.routes.draw do
  root "welcome#home"

  # Essential informational & RGAA accessibility pages
  get "/how-it-works",  to: "welcome#how_it_works",  as: :how_it_works
  get "/privacy",       to: "welcome#privacy",       as: :privacy
  get "/accessibility", to: "welcome#accessibility", as: :accessibility

  # Authentication & profile
  get    "/signup",       to: "users#new",           as: :signup
  get    "/signin",       to: "sessions#new",        as: :signin
  delete "/signout",      to: "sessions#destroy",    as: :signout
  post   "/demo-session", to: "demo_sessions#create", as: :demo_session
  resources :sessions, only: [:new, :create, :destroy]
  resources :users, only: [:new, :create, :show, :edit, :update]

  # Core B2B feature: Flight-Level Baggage Allowance Exchange (Bid / Ask)
  resources :flights, only: [:index, :show] do
    resources :kilo_orders, only: [:create] do
      member do
        patch :cancel
      end
    end
  end

  # Passenger PNR Wallet & active orders
  get "/my-bookings", to: "passenger_bookings#index", as: :my_bookings

  # Airline Executive ROI Dashboard & Annual Fleet Simulator
  get "/airline-roi",  to: "airline_roi#show",   as: :airline_roi
  get "/integrations", to: "integrations#index", as: :integrations

  # Signed Inbound Airline DCS / PSS Webhook API (HMAC-SHA256)
  namespace :api do
    namespace :v1 do
      post "dcs/webhooks/:airline_code", to: "dcs_webhooks#create", as: :dcs_webhook
    end
  end

  # Notifications
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end
end
