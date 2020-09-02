Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  devise_for :users, :controllers => { omniauth_callbacks: "callbacks", sessions: "users/sessions", passwords: "users/passwords" }

  resource :member, only: [:show] do
    get "/:reservation_date(/r/:reservation_id)", to: "members#show", on: :collection, constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :date
  end
  post "member", to: "members#show"

  scope module: :liff, path: :liff, as: :liff do
    get :identify_line_user_for_connecting_shop_customer
  end

  scope module: :lines, path: :lines, as: :lines do
    get "/identify_shop_customer/(:social_user_id)", action: "identify_shop_customer", as: :identify_shop_customer
    get :find_customer
    post :create_customer
    get :identify_code
    get :ask_identification_code
  end

  resources :users, only: [] do
    resources :customers, only: [:index] do
      collection do
        get :filter
        get :search
        get :recent
        get :detail
        delete :delete
        post :save
        post :toggle_reminder_premission
        get  "/data_changed/:reservation_customer_id", to: "customers#data_changed", as: :data_changed
        patch "/save_changes/:reservation_customer_id", to: "customers#save_changes", as: :save_changes
      end
    end

    scope module: :users do
      resources :chats, only: [:index]
    end
  end

  scope module: :users do
    resource :profile, only: %i[new create]
    resources :web_push_subscriptions, only: %i[create]
  end

  resources :shops, only: [] do
    resources :reservations, except: [:edit, :new] do
      get "/:reservation_date", to: "reservations#index", on: :collection, constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :date
      collection do
        post :validate
        post :add_customer
        get "form/(:id)", action: :form, as: :form
      end

      scope module: "reservations" do
        resource :states, only: [] do
          get :pend
          get :accept
          get :accept_in_group
          get :check_in
          get :check_out
          get :cancel
        end
      end
    end

    namespace :reservations do
      resource :available_options, only: [] do
        get :times
        get :menus
        get :staffs
      end
    end
  end

  scope module: "customers", as: "customer", path: "customer" do
    resources :users, only: [] do
      resources :printing, only: [:new, :create]
      resources :reservations, only: [:index] do
        collection do
          get "/:reservation_id/pend/:customer_id", action: :pend, as: :pend
          get "/:reservation_id/accept/:customer_id", action: :accept, as: :accept
          get "/:reservation_id/cancel/:customer_id", action: :cancel, as: :cancel
        end
      end

      resources :filter, only: [:index, :create]
      resources :saved_filters, only: [:index, :create] do
        collection do
          get :fetch
          delete :delete
        end
      end
    end
  end

  scope module: "reservations", as: "reservation", path: "reservation" do
    resources :users, only: [] do
      resources :filter, only: [:index, :create]
      resources :saved_filters, only: [:index, :create] do
        collection do
          get :fetch
          delete :delete
        end
      end
    end
  end

  namespace :settings do
    get :dashboard, to: "dashboards#index", as: :dashboard
    get :tour, to: "dashboards#tour", as: :tour
    get :end_tour, to: "dashboards#end_tour", as: :end_tour
    get :hide_tour_warning, to: "dashboards#hide_tour_warning", as: :hide_tour_warning
    get :booking_tour, to: "dashboards#booking_tour", as: :booking_tour

    namespace :tours, constraints: ::XhrConstraint do
      get :current_step_warning
      get :business_schedule
      get :contact_group
      get :menu
      get :reservation_setting
      get :working_time
      get :shop
    end

    resources :plans, only: [:index]
    resources :payments, only: [:index, :create] do
      collection do
        get :refund
        get :downgrade
      end

      member do
        get :receipt
      end
    end
    resources :referrers, only: [:index] do
      get :copy_modal, on: :collection
    end
    resources :withdrawals, only: [:index, :show]
    resource :profile, only: %i[show edit update]

    resources :users, only: [] do
      get :dashboard, to: "dashboards#index", as: :dashboard
      resources :staffs, except: [:show] do
        collection do
          get :resend_activation_email
        end

        member do
          get "shop/:shop_id/edit", to: "staffs#edit", as: :edit_at_shop
        end
      end
      resources :business_schedules, only: [:index]
      resources :menus, except: [:show] do
        get :repeating_dates, on: :collection
      end
      resources :booking_options, except: [:show]
      resources :booking_pages, except: [:show] do
        get :copy_modal, on: :member
        collection do
          get :validate_special_dates
          get :business_time
          get :booking_options
        end
      end
      resources :reservation_settings, except: [:show]
      resources :categories, except: [:show]
      resources :ranks, except: [:show]

      namespace :working_time do
        resources :staffs, only: [:index, :update] do
          member do
            get :working_schedules
          end
        end
      end

      resources :shops, except: [:show] do
        resources :business_schedules, only: [] do
          collection do
            get "edit"
            post "update", as: :update
          end
        end
      end

      resources :contact_groups do
        member do
          post "sync"
          post "bind"
          get "connections"
        end
      end

      resources :social_accounts
    end
  end
  resources :custom_schedules, only: [:create, :update, :destroy]

  namespace :callbacks do
    resources :staff_accounts, only: [] do
      get ":token", to: "staff_accounts#create", on: :collection, as: :user_from # user_from_callbacks_staff_accounts
    end

    resources :reminder_permissions, only: [] do
      get ":encrypted_data", to: "reminder_permissions#create", on: :collection, as: :customer_from # customer_from_callbacks_reminder_permissions
    end
  end

  namespace :webhooks do
    post "line/:channel_id", to: "lines#create", as: :line
  end

  resources :calendars, only: [] do
    collection do
      get "working_schedule"
      get "personal_working_schedule"
      get "booking_page_settings"
    end
  end

  resources :warnings, only: [], constraints: ::XhrConstraint do
    collection do
      get :shop_dashboard_for_staff
      get :shop_dashboard_for_admin
      get :customer_dashboard_for_staff
      get :filter_dashboard_for_staff
      get :read_settings_dashboard_for_staff
      get :edit_staff_for_admin
      get :new_staff_for_admin
      get :create_reservation
      get :admin_upgrade_filter_modal
    end
  end

  authenticated :user, -> user { user.super_admin? || Rails.env.development? } do
    mount Delayed::Web::Engine, at: "/_jobs"
    mount PgHero::Engine, at: "/_pghero"

    namespace :admin do
      get "as_user"
      get "/", to: "dashboards#index"

      resources :business_applications, only: [:index] do
        member do
          post "approve"
          post "reject"
        end
      end

      resources :withdrawals, only: [] do
        member do
          post "mark_paid"
          get "receipt"
        end
      end
    end
  end

  root to: "members#show"

  resources :booking_pages, only: [:show] do
    member do
      post "booking_reservation"
      get "find_customer"
      get "ask_confirmation_code"
      get "confirm_code"
      get "calendar"
      get "booking_times"
    end
  end
  resources :shops, only: [:show]

  resources :referrals, only: [:show], param: :token
  resource :business, only: [:show] do
    collection do
      post :apply
      post :pay
    end
  end
end
