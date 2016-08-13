Rails.application.routes.draw do
  resources :shops do
    resources :customers
    resources :reservations

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
