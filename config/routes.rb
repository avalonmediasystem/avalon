Avalon::Application.routes.draw do

  mount BrowseEverything::Engine => '/browse'
#  HydraHead.add_routes(self)

      get '/bookmarks/delete', as: :delete_bookmarks
      post '/bookmarks/delete'
      get '/bookmarks/move', as: :move_bookmarks
      post '/bookmarks/move'
      get '/bookmarks/update_access_control', as: :update_access_control_bookmarks
      post '/bookmarks/update_access_control'
      post '/bookmarks/publish', as: :publish_bookmarks
      post '/bookmarks/unpublish', as: :unpublish_bookmarks

  post '/media_objects/set_session_quality'

  #Blacklight catalog routes
  blacklight_for :catalog
  #match "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet', via: [:get]
  #match "catalog", :to => 'catalog#index', :as => 'catalog_index', via: [:get]

  root :to => "catalog#index"

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }, format: false
  devise_scope :user do
    match '/users/sign_in', :to => "users/sessions#new", :as => :new_user_session, via: [:get]
    match '/users/sign_out', :to => "users/sessions#destroy", :as => :destroy_user_session, via: [:get]
  end
  match "/authorize", to: 'derivatives#authorize', via: [:get, :post]
  match "/authorize/:path", to: 'derivatives#authorize', via: [:get, :post]
  match "/autocomplete", to: 'object#autocomplete', via: [:get]
  match "/oembed", to: 'master_files#oembed', via: [:get]

  match "object/:id", to: 'object#show', via: [:get], :as => :object

  resources :vocabulary, except: [:create, :destroy, :new, :edit]

  resources :media_objects, except: [:create, :update] do
    member do
      put :update, action: :update, defaults: { format: 'html' }, constraints: { format: 'html' }
      put :update, action: :json_update, constraints: { format: 'json' }
      patch :update, action: :update, defaults: { format: 'html' }, constraints: { format: 'html' }
      put :update_status
      get :progress, :action => :show_progress
      get 'content/:datastream', :action => :deliver_content, :as => :inspect
      get 'track/:part', :action => :show, :as => :indexed_section
      get 'section/:content', :action => :show, :as => :pid_section
      get 'tree', :action => :tree, :as => :tree
      get :confirm_remove
    end
    collection do
      post :create, action: :create, constraints: { format: 'json' }
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

  match '/media_objects/:media_object_id/section/:id/embed' => 'master_files#embed', via: [:get]
  resources :derivatives, only: [:create]
  resources :playlists do
    resources :playlist_items, path: 'items', only: [:create, :update]
    member do
      patch 'update_multiple'
      delete 'update_multiple'
    end
  end

  resources :avalon_annotation, only: [:create, :show, :update, :destroy]

  resources :comments, only: [:index, :create]

  resources :playlist_items, only: [:update], :constraints => {:format => /(js|json)/}

  #match 'search/index' => 'search#index'
  #match 'search/facet/:id' => 'search#facet'


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

  resources :dropbox, :only => [] do
    collection do
      delete :bulk_delete
    end
  end

  mount AboutPage::Engine => '/about(.:format)', :as => 'about_page'

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
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

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => "welcome#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
