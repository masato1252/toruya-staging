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

      scope module: "reservations" do
        resource :states, only: [] do
          put :pend
          put :accept
          put :check_in
          put :check_out
          put :cancel
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
        put :state
        get :edit
      end
    end
  end

  namespace :settings do
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
      resources :staffs, only: [:index, :edit, :update]
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

  devise_for :users, :controllers => { omniauth_callbacks: "callbacks" }

  authenticated :user, -> user { user.super_admin? } do
    mount Delayed::Web::Engine, at: "/_jobs"
  end

  root to: "home#index"
end
