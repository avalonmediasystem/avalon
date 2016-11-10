  Rails.application.routes.draw do

  mount Blacklight::Engine => '/'
  root to: "catalog#index"
    concern :searchable, Blacklight::Routes::Searchable.new

  resource :catalog, only: [:index], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  concern :exportable, Blacklight::Routes::Exportable.new

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
      get 'delete'#, as: :delete_bookmarks
      post 'delete'
      get 'move'#, as: :move_bookmarks
      post 'move'
      get 'update_access_control'#, as: :update_access_control_bookmarks
      post 'update_access_control'
      post 'publish'#, as: :publish_bookmarks
      post 'unpublish'#, as: :unpublish_bookmarks
      get 'add_to_playlist'
      post 'add_to_playlist'
    end
  end

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }, format: false
  devise_scope :user do
    match '/users/sign_in', :to => "users/sessions#new", :as => :new_user_session, via: [:get]
    match '/users/sign_out', :to => "users/sessions#destroy", :as => :destroy_user_session, via: [:get]
    match '/users/auth/:provider', to: 'users/omniauth_callbacks#passthru', as: :user_omniauth_authorize, via: [:get, :post]
    match '/users/auth/:action/callback', controller: "users/omniauth_callbacks", as: :user_omniauth_callback, via: [:get, :post]
  end

  mount BrowseEverything::Engine => '/browse'

  # Avalon routes
  match "/authorize", to: 'derivatives#authorize', via: [:get, :post]
  match "/authorize/:path", to: 'derivatives#authorize', via: [:get, :post]

  namespace :admin do
    resources :groups, except: [:show] do
      collection do
        put 'update_multiple'
      end
      member do
        put 'update_users'
      end
    end
    resources :collections do
      member do
        get 'edit'
        get 'remove'
        get 'items'
      end
    end
  end

  resources :vocabulary, except: [:create, :destroy, :new, :edit]

  resources :media_objects, except: [:create, :update] do
    member do
      put :update, action: :update, defaults: { format: 'html' }, constraints: { format: 'html' }
      put :update, action: :json_update, constraints: { format: 'json' }
      patch :update, action: :update, defaults: { format: 'html' }, constraints: { format: 'html' }
      put :update_status
      get :progress, :action => :show_progress
      get 'content/:file', :action => :deliver_content, :as => :inspect
      get 'track/:part', :action => :show, :as => :indexed_section
      get 'section/:content', :action => :show, :as => :id_section
      get 'tree', :action => :tree, :as => :tree
      get :confirm_remove
    end
    collection do
      post :create, action: :create, constraints: { format: 'json' }
      post :set_session_quality
      get :confirm_remove
      put :update_status
      # 'delete' has special signifigance so use 'remove' for now
      delete :remove, :action => :destroy
    end
  end

  resources :master_files, except: [:new, :index, :update] do
    member do
      get  'thumbnail', :to => 'master_files#get_frame', :defaults => { :type => 'thumbnail' }
      get  'poster',    :to => 'master_files#get_frame', :defaults => { :type => 'poster' }

      post 'thumbnail', :to => 'master_files#set_frame', :defaults => { :type => 'thumbnail', :format => 'html' }
      post 'poster',    :to => 'master_files#set_frame', :defaults => { :type => 'poster', :format => 'html' }
      post 'still',     :to => 'master_files#set_frame', :defaults => { :format => 'html' }
      get :embed
      post 'attach_structure'
      post 'attach_captions'
      get :captions
    end
  end

  resources :derivatives, only: [:create]

  match "/autocomplete", to: 'objects#autocomplete', via: [:get]
  match "/objects/:id", to: 'objects#show', via: [:get], :as => :objects

  resources :playlists do
    resources :playlist_items, path: 'items', only: [:create, :update]
    member do
      patch 'update_multiple'
      delete 'update_multiple'
    end
    collection do
      if Avalon::Configuration.has_key?('variations')
        post 'import_variations_playlist'
      end
    end
  end

  resources :avalon_marker, only: [:create, :show, :update, :destroy]

  resources :comments, only: [:index, :create]

  resources :playlist_items, only: [:update], :constraints => {:format => /(js|json)/}

  resources :dropbox, :only => [] do
    collection do
      delete :bulk_delete
    end
  end

  match "/oembed", to: 'master_files#oembed', via: [:get]
  
  require 'resque/server'
  mount Resque::Server, at: '/jobs'

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
