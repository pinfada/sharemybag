Rails.application.routes.draw do
  mount Blazer::Engine, at: "blazer"
  mount RailsAdmin::Engine => '/dashboard', as: 'rails_admin'

  root 'welcome#home'

  # Authentication
  match 'auth/:provider/callback', to: 'identities#omniauth', via: [:get, :post]
  match 'auth/failure',            to: redirect('/'), via: [:get, :post]
  match '/signup',                 to: 'users#new', via: 'get'
  match '/signin',                 to: 'sessions#new', via: 'get'
  match '/signout',                to: 'sessions#destroy', via: 'delete'

  # Legacy routes
  match '/vol',                    to: 'vols#index', via: 'get'
  match '/coordonnee',             to: 'coordonnees#index', via: 'get'
  match '/reservation',            to: 'bookings#new', via: 'get'
  match '/bagage',                 to: 'bagages#new', via: 'get'
  match '/paquet',                 to: 'paquets#new', via: 'get'
  match '/listevol',               to: 'welcome#search', via: 'get'
  match '/home',                   to: 'welcome#home', via: 'get'

  # Static pages
  match '/help',                   to: 'welcome#help', via: 'get'
  match '/propos',                 to: 'welcome#about', via: 'get'
  match '/contact',                to: 'welcome#contact', via: 'get'
  match '/policy',                 to: 'welcome#policy', via: 'get'
  match '/team',                   to: 'welcome#team', via: 'get'

  # === MARKETPLACE: Shipping Requests (Reverse Auction) ===
  resources :shipping_requests do
    member do
      post :accept_bid
    end
    collection do
      get :my_requests
    end
    resources :bids, only: [:create] do
      member do
        patch :withdraw
      end
    end
    resources :reviews, only: [:create]

    # === Security & Compliance ===
    resource :customs_declaration, only: [:new, :create, :show]
    resource :compliance, only: [], controller: 'compliance' do
      get :checklist
      post :submit_checklist
    end
  end

  # === MARKETPLACE: Kilo Offers ===
  resources :kilo_offers do
    collection do
      get :my_offers
    end
  end

  # === Bids ===
  resources :bids, only: [] do
    collection do
      get :my_bids
    end
  end

  # === Messaging ===
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end

  # === Notifications ===
  resources :notifications, only: [:index] do
    member do
      patch :mark_as_read
    end
    collection do
      patch :mark_all_as_read
    end
  end

  # === Shipment Tracking ===
  resources :shipment_trackings, only: [:show] do
    member do
      post :hand_over
      post :mark_in_transit
      post :deliver
      post :confirm
    end
    # === OTP Delivery Confirmation (US003) ===
    resource :delivery_confirmation, only: [] do
      post :generate
      post :verify
      post :resend
    end

    # === Chain of Custody (Security) ===
    resources :handling_events, only: [:index, :create]
  end

  # === Identity Verification (US004 - KYC) ===
  resource :identity_verification, only: [:new, :create, :show]

  # === Payments (US001 - Stripe Connect) ===
  resources :payments, only: [] do
    member do
      post :checkout
      get :success
      get :cancel
      get :status
    end
  end

  # === Stripe Connect Account (US001) ===
  resource :stripe_account, only: [] do
    get :onboarding
    get :return_from_onboarding, path: 'return'
    get :refresh
    get :dashboard
    get :status
  end

  # === Stripe Webhooks ===
  namespace :webhooks do
    post 'stripe', to: 'stripe#create'
  end

  # === Flight Verification (US002) ===
  resources :kilo_offers, only: [] do
    resource :flight_verification, only: [:show, :create]
  end

  # === Disputes (US005) ===
  resources :disputes do
    member do
      post :add_evidence
      post :add_message
      post :escalate
      post :resolve
      post :close
    end
  end

  # Admin Disputes Dashboard
  get 'admin/disputes', to: 'disputes#admin_index', as: :admin_disputes

  # === Admin Compliance Review ===
  get 'admin/compliance', to: 'compliance#admin_review', as: :admin_compliance_review
  post 'admin/compliance/:id/approve', to: 'compliance#approve', as: :admin_compliance_approve
  post 'admin/compliance/:id/reject', to: 'compliance#reject', as: :admin_compliance_reject

  # Existing resources
  resources :coordonnees, only: [:index, :new, :edit, :show]
  resources :sessions, only: [:new, :create, :destroy]
  resources :relationships, only: [:create, :destroy]
  resources :identities
  resources :microposts, only: [:create, :destroy]
  resources :vols, only: :index
  resources :bookings, only: [:new, :create, :show]
  resources :paquets

  concern :bagageable do
    resources :bagages
  end

  resources :users, concerns: [:bagageable] do
    member do
      get :following, :followers
    end
  end
end
