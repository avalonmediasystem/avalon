require 'avalon/routing/can_constraint'

Rails.application.routes.draw do
  mount Samvera::Persona::Engine => '/'
  mount Blacklight::Engine => '/catalog'
  concern :searchable, Blacklight::Routes::Searchable.new
  concern :exportable, Blacklight::Routes::Exportable.new

  resource :catalog, only: [], as: 'catalog', path: '/catalog', controller: 'catalog' do
    concerns :searchable
  end

  # For some reason this needs to be after `resource :catalog` otherwise Blacklight will generate links to / instead of /catalog
  root to: "catalog#index"

  get '/mejs/:version', to: 'application#mejs'

  resources :solr_documents, only: [:show], path: '/catalog', controller: 'catalog' do
    concerns :exportable
  end

  resources :encode_records, only: [:show, :index] do
    collection do
      post :paged_index
      post :progress
    end
  end

  resources :checkouts, only: [:index, :create, :show, :update, :destroy], :constraints => lambda { |request| Avalon::Configuration.controlled_digital_lending_enabled? } do
    collection do
      patch :return_all
    end

    member do
      patch :return
    end
  end

  resources :bookmarks do
    concerns :exportable

    collection do
      delete 'clear'
      delete 'remove_selected', action: :destroy_selected
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
      get 'intercom_push'
      post 'intercom_push'
      get 'merge'
      post 'merge'
      get 'count', constraints: { format: 'json' }
    end
  end

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks', sessions: 'users/sessions' }
  devise_scope :user do
    match '/users/auth/:provider', to: 'users/omniauth_callbacks#passthru', as: :user_omniauth_authorize, via: [:get, :post]
    Avalon::Authentication::Providers.collect { |provider| provider[:provider] }.uniq.each do |provider_name|
      match "/users/auth/#{provider_name}/callback", to: "users/omniauth_callbacks##{provider_name}", as: "user_omniauth_callback_#{provider_name}".to_sym, via: [:get, :post]
    end
  end

  mount BrowseEverything::Engine => '/browse'

  # Avalon routes
  match "/authorize", to: 'derivatives#authorize', via: [:get, :post]
  match "/authorize/:path", to: 'derivatives#authorize', via: [:get, :post]

  namespace :admin do
    get '/dashboard', to: 'dashboard#index'
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
        get 'poster'
        post 'poster', action: :attach_poster, as: 'attach_poster'
        delete 'poster', action: :remove_poster, as: 'remove_poster'
      end
    end
    resources :units do
      member do
        get 'edit'
        get 'remove'
        get 'items'
        get 'poster'
        post 'poster', action: :attach_poster, as: 'attach_poster'
        delete 'poster', action: :remove_poster, as: 'remove_poster'
      end
    end

    namespace :migration_report, controller: '/migration_status' do
      get '/', action: :index
      get ':class', action: :show, as: 'by_class'
      get ':id/detail', action: :detail, as: 'detail'
      get ':id/report', action: :report, as: 'report'
    end
  end

  resources :vocabulary, except: [:create, :destroy, :new, :edit]

  resources :collections, only: [:index, :show] do
    member do
      get :poster
    end
  end

  resources :units, only: [:index, :show] do
    member do
      get :poster
    end
  end

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
      get 'section/:content/stream', :action => :show_stream_details, :as => :section_stream
      get 'section/:content/embed', :to => redirect('/master_files/%{content}/embed')
      get 'tree', :action => :tree, :as => :tree
      get :confirm_remove
      post :add_to_playlist
      patch :intercom_push
      get :manifest
      get :move_preview, defaults: { format: 'json' }, constraints: { format: 'json' }
    end
    collection do
      post :create, action: :create, constraints: { format: 'json' }
      post :set_session_quality
      get :confirm_remove
      put :update_status
      # 'delete' has special signifigance so use 'remove' for now
      delete :remove, :action => :destroy
      get :intercom_collections
    end

    # Supplemental Files
    resources :supplemental_files, except: [:new, :index, :edit] do
      get :index, constraints: { format: 'json' }, on: :collection
    end
  end

  resources :master_files, except: [:new, :index] do
    member do
      get  'thumbnail', :to => 'master_files#get_frame', :defaults => { :type => 'thumbnail' }
      get  'poster',    :to => 'master_files#get_frame', :defaults => { :type => 'poster' }

      post 'thumbnail', :to => 'master_files#set_frame', :defaults => { :type => 'thumbnail', :format => 'html' }
      post 'poster',    :to => 'master_files#set_frame', :defaults => { :type => 'poster', :format => 'html' }
      post 'still',     :to => 'master_files#set_frame', :defaults => { :format => 'html' }
      get :embed
      post 'attach_structure'
      get :captions
      get :waveform
      match ':quality.m3u8', to: 'master_files#hls_manifest', via: [:get], as: :hls_manifest
      get 'structure', to: 'master_files#structure', constraints: { format: 'json' }
      post 'structure', to: 'master_files#set_structure', constraints: { format: 'json' }
      delete 'structure', to: 'master_files#delete_structure', constraints: { format: 'json' }
      post 'move'
      get 'transcript/:t_id', to: 'master_files#transcript'
      get :search
      
      if Settings.derivative.allow_download
        get :download_derivative
      end
    end

    # Supplemental Files
    resources :supplemental_files, except: [:new, :index, :edit] do
      member do
        get 'captions'
        get 'transcripts', :to => redirect('/master_files/%{master_file_id}/supplemental_files/%{id}')
        get 'descriptions', :to => redirect('master_files/%{master_file_id}/supplemental_files/%{id}')
      end
      get :index, constraints: { format: 'json' }, on: :collection
    end
  end

  match "iiif_auth_token/:id", to: 'master_files#iiif_auth_token', via: [:get], as: :iiif_auth_token

  resources :derivatives, only: [:create]
  match "/autocomplete", to: 'objects#autocomplete', via: [:get]
  match "/objects/:id", to: 'objects#show', via: [:get], :as => :objects
  match "/object/:id", to: 'objects#show', via: [:get]

  resources :playlists do
    resources :playlist_items, path: 'items', only: [:create, :update, :show] do
      get 'related_items'
    end
    member do
      patch 'update_multiple'
      delete 'update_multiple'
      patch 'regenerate_access_token'
      get 'refresh_info'
      get 'manifest'
    end
    collection do
      post 'duplicate'
      post 'paged_index'
      if Settings['variations'].present?
        post 'import_variations_playlist'
      end
    end
  end

  resources :avalon_marker, only: [:create, :show, :update, :destroy]

  resources :comments, only: [:index, :create]

  resources :playlist_items, only: [:update], :constraints => {:format => /(js|json)/}

  resources :timelines do
    member do
      patch 'regenerate_access_token'
      post 'manifest', to: 'timelines#manifest_update', constraints: { format: 'json' }
      get 'manifest'
    end
    collection do
      post 'duplicate'
      post 'paged_index'
      if Settings['variations'].present?
        post 'import_variations_timeline'
      end
    end
  end
  get '/timeliner', to: 'timelines#timeliner', as: :timeliner

  resources :dropbox, :only => [] do
    collection do
      delete :bulk_delete
    end
  end

  match "/oembed", to: 'master_files#oembed', via: [:get]

  constraints(Avalon::Routing::CanConstraint.new(:read, :about_page)) do
    mount AboutPage::Engine => '/about(.:format)', as: 'about_page'
  end
  get '/about(.:format)', to: redirect('/')
  get '/about/health.yaml', to: 'about_page/about#health', defaults: { :format => 'yaml' }
  get '/about/health(.:format)', to: redirect('/')

  constraints(Avalon::Routing::CanConstraint.new(:manage, :jobs)) do
    mount Sidekiq::Web, at: '/jobs', as: 'jobs'
  end
  get '/jobs(.:format)', to: redirect('/')

  scope :persona, as: 'persona' do
    resources :users, only: [], controller: 'samvera/persona/users' do
      collection do
        post 'paged_index'
      end
    end
  end
end
