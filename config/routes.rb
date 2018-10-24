Rails.application.routes.draw do
  #get 'welcome/home'
  root 'welcome#home'
  match 'auth/:provider/callback', to: 'identities#omniauth', via: [:get, :post]
  match 'auth/failure', to: redirect('/'), via: [:get, :post]
  match '/vol', to: 'vols#index', via: 'get'
  match '/coordonnee', to: 'coordonnees#index', via: 'get'
  match '/reservation', to: 'bookings#new', via: 'get'
  match '/bagage', to: 'bagages#new', via: 'get'
  match '/paquet', to: 'paquets#new', via: 'get'
  match '/signup', to: 'users#new', via: 'get'
  match '/signin', to: 'sessions#new', via: 'get'
  match '/signout', to: 'sessions#destroy', via: 'delete'
  match '/help', to: 'welcome#help', via: 'get'
  match '/propos', to: 'welcome#propos', via: 'get'
  match '/contact', to: 'welcome#contact', via: 'get'
  match '/listevol', to: 'welcome#search', via: 'get'
  match '/home', to: 'welcome#home', via: 'get'

  resources :coordonnees, only:  [:index, :new, :edit, :show]
  resources :sessions, only: [:new, :create, :destroy]
  resources :relationships, only: [:create, :destroy]
  resources :identities
  resources :microposts, only: [:create, :destroy]
  resources :vols,  only:  :index
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

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
