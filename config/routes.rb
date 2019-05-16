Rails.application.routes.draw do
  devise_for :users, :controllers => { omniauth_callbacks: "callbacks", sessions: "users/sessions", passwords: "users/passwords" }

  resource :member, only: [:show] do
    get "/:reservation_date(/r/:reservation_id)", to: "members#show", on: :collection, constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :date
  end
  post "member", to: "members#show"

  resources :users, only: [] do
    resources :customers, only: [:index] do
      collection do
        get :filter
        get :search
        get :recent
        get :detail
        delete :delete
        post :save
      end
    end
  end

  scope module: :users do
    resource :profile, only: %i[new create]
  end

  resources :shops, only: [] do
    resources :reservations do
      get "/:reservation_date", to: "reservations#index", on: :collection, constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :date
      collection do
        get :validate
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
      resources :reservations, only: [:index]
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
        get :validate_special_dates, on: :collection
        get :business_time, on: :collection
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
    end
  end
  resources :custom_schedules, only: [:create, :update, :destroy]

  namespace :callbacks do
    resources :staff_accounts, only: [] do
      get ":token", to: "staff_accounts#create", on: :collection, as: :user_from # user_from_callbacks_staff_accounts
    end
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

    scope path: "admin"do
      get "as_user", to: "admin#as_user"
    end
  end

  root to: "members#show"

  constraints(SubdomainConstraint[:booking]) do
    get "page/:id", to: "booking_pages#show", as: :booking_page
  end
end
