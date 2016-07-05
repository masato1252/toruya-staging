Rails.application.routes.draw do
  namespace :settings do
    resources :shops
  end

  devise_for :users
  root to: "home#index"
end
