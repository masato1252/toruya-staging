Rails.application.routes.draw do
  namespace :settings do
    resources :shops do
      resources :staffs
    end
  end

  devise_for :users
  root to: "home#index"
end
