Loomio::Application.routes.draw do

  ActiveAdmin.routes(self)

  namespace :admin do
    resource :email_groups, only: [:create, :new]
  end

  get "/groups", to: 'groups/public_groups#index', as: :public_groups

  resource :search, only: :show

  devise_for :users, controllers: { sessions: 'users/sessions',
                                    registrations: 'users/registrations' }

  get "/inbox", to: "inbox#index", as: :inbox
  get "/inbox/size", to: "inbox#size", as: :inbox_size
  get '/inbox/preferences', to: 'inbox#preferences', as: :inbox_preferences
  put '/inbox/update_preferences', to: 'inbox#update_preferences', as: :update_inbox_preferences
  match '/inbox/mark_as_read', to: 'inbox#mark_as_read', as: :mark_as_read_inbox
  match '/inbox/mark_all_as_read/:id', to: 'inbox#mark_all_as_read', as: :mark_all_as_read_inbox
  match '/inbox/unfollow', to: 'inbox#unfollow', as: :unfollow_inbox

  resources :invitations, only: [:show]

  resources :group_requests, only: [:create, :new] do
    collection do
      get :confirmation
    end
  end

  resources :groups, except: [:index, :new] do
    resources :invitations, only: [:index, :destroy, :new, :create], controller: 'groups/invitations'
    resources :memberships, only: [:index, :destroy, :new, :create], controller: 'groups/memberships' do
      member do
       post :make_admin
       post :remove_admin
      end
    end
    resource :subscription, only: [:new, :show, :create], controller: 'groups/subscriptions' do
      collection do
        get :confirm
        get :payment_failed
      end
    end

    get :setup, on: :member, to: 'groups/group_setup#setup'
    put :finish, on: :member, to: 'groups/group_setup#finish'

    post :add_members, on: :member
    post :hide_next_steps, on: :member
    get :add_subgroup, on: :member

    resources :motions
    resources :discussions, only: [:index, :new]
    post :email_members, on: :member
    post :edit_description, on: :member
    post :edit_privacy, on: :member
    delete :leave_group, on: :member
  end

  get 'groups/:group_id/request_membership',   to: 'groups/membership_requests#new',          as: :new_group_membership_request
  post 'groups/:group_id/membership_requests', to: 'groups/membership_requests#create'  ,       as: :group_membership_requests
  delete 'membership_requests/:id/cancel',     to: 'groups/membership_requests#cancel',       as: :cancel_membership_request

  get 'groups/:group_id/membership_requests',  to: 'groups/manage_membership_requests#index', as: :group_membership_requests
  resources :membership_requests, only: [], controller: 'groups/manage_membership_requests' do
    member do
      post :approve
      post :ignore
    end
  end

  match "/groups/archive/:id", :to => "groups#archive", :as => :archive_group, :via => :post
  match "/groups/:id/members", :to => "groups#get_members", :as => :get_members, :via => :get

  resources :motions do
    resources :votes, only: [:new, :edit, :create, :update]
    post :get_and_clear_new_activity, on: :member
    put :close, :on => :member
    put :edit_outcome, :on => :member
    put :edit_close_date, :on => :member
  end

  resources :discussions, except: [:edit] do
    get :activity_counts, on: :collection
    post :update_description, :on => :member
    post :add_comment, :on => :member
    post :show_description_history, :on => :member
    get :new_proposal, :on => :member
    post :edit_title, :on => :member
    put :move, :on => :member
  end

  post "/discussion/:id/preview_version/(:version_id)", :to => "discussions#preview_version", :as => "preview_version_discussion"
  post "/discussion/update_version/:version_id", :to => "discussions#update_version", :as => "update_version_discussion"

  resources :notifications, :only => :index do
    get :groups_tree_dropdown, on: :collection
    get :dropdown_items, on: :collection
    post :mark_as_viewed, :on => :collection, :via => :post
  end


  resources :users, :only => [:new, :update, :show] do
    put :set_avatar_kind, on: :member
    post :upload_new_avatar, on: :member
  end

  match '/announcements/:id/hide', to: 'announcements#hide', as: 'hide_announcement'

  match "/users/dismiss_system_notice", :to => "users#dismiss_system_notice",
        :as => :dismiss_system_notice_for_user, :via => :post
  match "/users/dismiss_dashboard_notice", :to => "users#dismiss_dashboard_notice",
        :as => :dismiss_dashboard_notice_for_user, :via => :post
  match "/users/dismiss_group_notice", :to => "users#dismiss_group_notice",
        :as => :dismiss_group_notice_for_user, :via => :post
  match "/users/dismiss_discussion_notice", :to => "users#dismiss_discussion_notice",
        :as => :dismiss_discussion_notice_for_user, :via => :post

  resources :comments , only: :destroy do
    post :like, on: :member
  end

  get '/users/invitation/accept' => redirect {|params, request|  "/invitations/#{request.query_string.gsub('invitation_token=','')}"}
  get '/group_requests/:id/start_new_group' => redirect {|params, request|  "/invitations/#{request.query_string.gsub('token=','')}"}

  match "/settings", :to => "users#settings", :as => :user_settings
  match 'email_preferences', :to => "users/email_preferences#edit", :as => :email_preferences, :via => :get
  match 'email_preferences', :to => "users/email_preferences#update", :as => :update_email_preferences, :via => :put

  resources :contributions, only: [:index, :create] do
    get :callback, on: :collection
    get :thanks, on: :collection
  end

  authenticated do
    root :to => 'dashboard#show'
  end

  root :to => 'pages#home'

  scope controller: 'pages' do
    get :about
    get :privacy
    get :pricing
    get :terms_of_service
    get :browser_not_supported
  end

  scope controller: 'help' do
    get :help
  end

  get 'we_the_people' => redirect('/')
  get 'collaborate' => redirect('/')
  get 'woc' => redirect('/')

  resources :contact_messages, only: [:new, :create,]
  match '/contact', to: 'contact_messages#new'

  #redirect from wall to new group signup
  get "group_requests/selection", to: "group_requests#new"
  get "group_requests/subscription", to: "group_requests#new"
  get "group_requests/pwyc", to: "group_requests#new"

  #redirect old invites
  match "/groups/:id/invitations/:token" => "group_requests#start_new_group"

  #redirect old pages:
  get '/pages/home' => redirect('/')
  get '/get*involved' => redirect('/about#how-it-works')
  get '/how*it*works' => redirect('/about#how-it-works')
  get '/pages/get*involved' => redirect('/about')
  get '/pages/how*it*works' => redirect('/about#how-it-works')
  get '/pages/privacy' => redirect('/privacy_policy')
  get '/pages/about' => redirect('/about#about-us')
  match '/pages/contact', to: 'contact_messages#new'

  resources :attachments, only: [:create, :new] do
    collection do
      get 'sign'
      get :iframe_upload_result
    end
  end

  get 'blog' => redirect('http://blog.loomio.org')
  get 'press' => redirect('http://blog.loomio.org/press-pack')
  get 'press-pack' => redirect('http://blog.loomio.org/press-pack')
end
