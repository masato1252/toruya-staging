Rails.application.routes.draw do
  resources :shops do
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

    resources :reservations, except: [:show] do
      get "/:reservation_date", to: "reservations#index", on: :collection, constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }
      collection do
        get :validate
      end

      scope module: "reservations" do
        resource :states, only: [] do
          get :pend
          get :accept
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
    resources :reservations, only: [:index] do
      collection do
        get :state
        get :edit
      end
    end

    resources :printing, only: [:new, :create]

    resources :users do
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
    resources :users do
      resources :filter, only: [:index, :create]
    end
  end

  namespace :settings do
    resources :users do
      resource :profile
      resources :staffs, except: [:show]
      resources :business_schedules, only: [:index]
      resources :menus, except: [:show] do
        get :repeating_dates, on: :collection
      end
      resources :reservation_settings, except: [:show]
      resources :categories, except: [:show]
      resources :ranks, except: [:show]

      namespace :working_time do
        resources :staffs, only: [:index, :update] do
          member do
            get :working_schedules
            get :holiday_schedules
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
  resources :custom_schedules, only: [:create]

  namespace :callbacks do
    resources :staff_accounts, only: [] do
      get ":token", to: "staff_accounts#create", on: :collection, as: :user_from # user_from_callbacks_staff_accounts
    end
  end
  devise_for :users, :controllers => { omniauth_callbacks: "callbacks", sessions: "users/sessions", passwords: "users/passwords" }
  resources :calendars, only: [] do
    collection do
      get "working_schedule"
    end
  end

  authenticated :user, -> user { user.super_admin? || Rails.env.development? } do
    mount Delayed::Web::Engine, at: "/_jobs"
  end

  get "settings/:super_user_id", to: "home#settings", as: :settings
  root to: "home#index"
end
