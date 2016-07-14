Rails.application.routes.draw do
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

  devise_for :users
  root to: "home#index"
end
