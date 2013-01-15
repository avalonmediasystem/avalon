Hydrant::Application.routes.draw do
  Blacklight.add_routes(self, except: [:bookmarks, :feedback, :catalog])
#  HydraHead.add_routes(self)

  #Blacklight catalog routes
  match "catalog/facet/:id", :to => 'catalog#facet', :as => 'catalog_facet'
  match "catalog", :to => 'catalog#index', :as => 'catalog_index'

  root :to => "mediaObjects#index"

  devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  devise_scope :user do 
    match '/users/sign_in', :to => "users/sessions#new", :as => :new_user_session
    match '/users/sign_out', :to => "users/sessions#destroy", :as => :destroy_user_session
  end
  match "/authorize", to: 'derivatives#authorize'

  # My routes go here
  # Routes for subjects and pbcore controller
  #resources :media_objects, except: [:index], as: :media
  #resources :master_files, as: :resources
  resources :media_objects, except: [:create] do
    member do
      get 'mobile'
      get :update_status
    end
  end
  resources :master_files, except: [:show, :new, :index] do
    member do
      get 'thumbnail'
      get 'poster'
    end
  end
  resources :derivatives, only: [:create]
  
  resources :comments, only: [:index, :create]

  match '/engage/ui/json/servicedata.:format' => 'media_objects#matterhorn_service_config'

  #match 'search/index' => 'search#index'
  #match 'search/facet/:id' => 'search#facet'

  resources :admin, only: [:index]
  namespace :admin do
    resources :groups, except: [:show] do 
      collection do 
        put 'update_multiple'
      end
    end
  end  

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
