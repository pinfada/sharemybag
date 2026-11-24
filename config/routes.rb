Rails.application.routes.draw do
  root 'welcome#home'

  # Essential informational & RGAA accessibility pages
  get '/how-it-works',  to: 'welcome#how_it_works',  as: :how_it_works
  get '/privacy',       to: 'welcome#privacy',       as: :privacy
  get '/accessibility', to: 'welcome#accessibility', as: :accessibility

  # Authentication
  get    '/signup',  to: 'users#new',        as: :signup
  get    '/signin',  to: 'sessions#new',     as: :signin
  delete '/signout', to: 'sessions#destroy', as: :signout
  resources :sessions, only: [:new, :create, :destroy]
  resources :users, only: [:new, :create, :show, :edit, :update]

  # Core feature: Shipping Requests & Reverse Auction
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
  end

  # Traveler offers
  resources :bids, only: [] do
    collection do
      get :my_bids
    end
  end

  # Secure handover & delivery tracking
  resources :shipment_trackings, only: [:show] do
    member do
      post :hand_over
      post :mark_in_transit
      post :deliver
      post :confirm
    end
  end

  # Contextual messaging
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
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
