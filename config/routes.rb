Rails.application.routes.draw do
  resources :shops do
    resources :customers, only: [:index] do
      collection do
        get :filter
        get :search
        get :recent
        delete :delete
        post :save
      end
    end

    resources :reservations do
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

  namespace :settings do
    resources :shops do
      resources :staffs
      resources :menus
      resources :business_schedules, only: [] do
        collection do
          get "edit"
          post "update", as: :update
        end
      end
    end
  end

  devise_for :users, :controllers => { omniauth_callbacks: "callbacks" }
  root to: "home#index"
end
