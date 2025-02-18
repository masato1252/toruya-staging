# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => '/cable'
  get "(/:locale)/userlogin", to: "lines#user_login", as: :user_login
  get "(/:locale)/userlogout", to: "lines#user_logout", as: :user_logout
  get '/redirect', to: 'function_redirects#redirect', as: :function_redirect

  # Customer verification routes
  namespace :customer_verification do
    post :generate_verification_code
    post :verify_code
    post :create_or_update_customer
  end

  scope module: :lines, path: :lines, as: :lines do
    # customer sesson new
    get "/identify_shop_customer/(:social_service_user_id)", action: "identify_shop_customer", as: :identify_shop_customer
    # customer sesson create
    post :customer_sign_in
    get "/contacts/social_service_user_id/:encrypted_social_service_user_id", action: "contacts", as: :contacts
    post :make_contact
    get :identify_code
    get :ask_identification_code
    put :update_customer_address

    scope module: :verification, path: :verification, as: :verification do
      get "/:encrypted_social_service_user_id", action: "show"
      get "/message_api_status/:encrypted_social_service_user_id", action: "message_api_status", as: :message_api_status
    end

    scope module: :customers, path: :customers, as: :customers do
      resources :online_service_purchases, only: [:create], param: :slug do
        collection do
          get "/:slug/new", action: "new", as: :new
        end
      end

      resource :dashboard, only: [] do
        collection do
          get "/:public_id/reservations(/:social_service_user_id)", action: "reservations", as: :reservations
          get "/:public_id/online_services(/:social_service_user_id)", action: "online_services", as: :online_services
        end
      end
    end

    scope module: :liff, path: :liff, as: :liff do
      get "/(:liff_path)", action: "index"
    end

    scope module: :liff, path: :twliff, as: :twliff do
      get "/(:liff_path)", action: "tw_index"
    end

    scope module: :user_bot, path: :user_bot, as: :user_bot do
      resource :change_log, only: [:update, :show]

      scope module: :users do
        get "/connect(/social_service_user_id/:social_service_user_id)", as: :connect_user, action: "connect" # user sign in
        get "/sign_up(/social_service_user_id/:social_service_user_id)", as: :sign_up, action: "sign_up" # user sign up
        get "(/:locale)/line_sign_up", as: :line_sign_up, action: "line_sign_up" # social user sign up
        get :generate_code
        get :identify_code
        post :create_user
        post :create_shop_profile
        get :check_shop_profile
      end

      resources :schedules, only: [] do
        collection do
          get "mine/:reservation_date(/r/:reservation_id)", to: "schedules#mine", constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :my_date
          get :mine
        end
      end

      resources :calendars, only: [] do
        collection do
          get "my_working_schedule"
          get "/social_service_user_id/:social_service_user_id", action: "my_working_schedule"
        end
      end

      # business owner scope START
      scope "/owner/(:business_owner_id)" do
        resources :schedules, only: [:index] do
          collection do
            get ":reservation_date(/r/:reservation_id)", to: "schedules#index", constraints: { reservation_date: /\d{4}-\d{1,2}-\d{1,2}/ }, as: :date
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end
        end

        resources :calendars, only: [] do
          collection do
            get "personal_working_schedule"
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end
        end
        namespace :metrics do
          get :dashboard, path: '/'
          get :sale_pages
          get :booking_pages
          get :online_services
          get "/online_services/:id", action: "online_service", as: :online_service, constraints: { id: /\d+/ }

          namespace :booking_pages do
            get :visits
            get :conversions
          end

          namespace :sale_pages do
            get :visits
            get :conversions
          end

          namespace :online_services do
            get "/:id/sale_pages_visits", action: :sale_pages_visits, as: :sale_pages_visits
            get "/:id/sale_pages_conversions", action: :sale_pages_conversions, as: :sale_pages_conversions
          end
        end

        resources :broadcasts, only: [:index, :new, :create, :show, :update, :edit] do
          collection do
            get "/new/social_service_user_id/:social_service_user_id", action: "new"
            get "/social_service_user_id/:social_service_user_id", action: "index"
            put :customers_count
          end

          member do
            put :draft
            put :activate
            post :clone
          end
        end

        resources :services, only: [:new, :create, :index, :show, :edit, :update, :destroy] do
          collection do
            get "/new/social_service_user_id/:social_service_user_id", action: "new"
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end

          resources :custom_messages, only: [:index], module: "services" do
            collection do
              get "/:scenario(/:id)", action: "edit_scenario", as: :edit_scenario
            end
          end

          resources :customers, only: [:index, :show], module: :services do
            member do
              post :approve
              delete :cancel
              put :change_expire_at
            end

            collection do
              post :assign
            end
          end

          resources :chapters, module: :services, only: [:index, :new, :edit, :update, :create, :destroy] do
            collection do
              put :reorder
            end
            resources :lessons, only: [:new, :create, :show, :edit] do
              resources :custom_messages, only: [:index], module: "lessons" do
                collection do
                  get "/:scenario(/:id)", action: "edit_scenario", as: :edit_scenario
                end
              end
            end
          end

          resources :lessons, module: :services, only: [:update, :destroy]

          resources :episodes, module: :services, only: [:index, :edit, :new, :create, :show, :update, :destroy] do
            resources :custom_messages, only: [:index], module: "episodes" do
              collection do
                get "/:scenario(/:id)", action: "edit_scenario", as: :edit_scenario
              end
            end
          end
        end

        resources :sales, only: [:new, :index, :show, :edit, :update, :destroy] do
          collection do
            get "/new/social_service_user_id/:social_service_user_id", action: "new"
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end

          member do
            post :clone
          end
        end

        scope module: :sales, as: :sales, path: :sales do
          resources :booking_pages, only: [:new, :create]
          resources :online_services, only: [:new, :create]
        end

        resources :custom_messages, only: [:destroy] do
          collection do
            put :update
            post :demo
          end
        end

        resources :bookings, only: [:new] do
          collection do
            get "/new/social_service_user_id/:social_service_user_id", action: "new"
            get :available_options
            post :page
          end
        end

        resources :booking_pages do
          collection do
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end

          member do
            delete "/booking_options/:booking_option_id", action: "delete_option", as: :delete_option
            get :preview_modal
            get :edit_booking_options_order
            put :update_booking_options_order
          end

          resources :custom_messages, only: [:index], module: "booking_pages" do
            collection do
              get "/:scenario(/:id)", action: "edit_scenario", as: :edit_scenario
            end
          end
        end

        resources :booking_options do
          collection do
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end

          member do
            delete "/menus/:menu_id", action: "delete_menu", as: :delete_menu
            patch :reorder_menu_priority
          end
        end

        resources :settings, only: [:index] do
          collection do
            get "/social_service_user_id/:social_service_user_id", action: "index"
          end
        end

        namespace :settings do
          resource :line_keyword, only: [] do
            member do
              get :edit_booking_pages
              put :upsert_booking_pages
              get :edit_booking_options
              put :upsert_booking_options
            end
          end
          resource :user_setting, only: [:edit, :update]

          resource :profile, only: %i[show edit update] do
            collection do
              get :company
            end
          end

          resources :plans, only: [:index]
          resources :payments, only: [:index, :create] do
            collection do
              get :refund
              get :downgrade
              put :change_card
            end

            member do
              get :receipt
            end
          end

          resource :stripe, only: %i[show update]
          resource :square, only: %i[show update]

          resource :social_account, only: [:new, :edit, :update] do
            member do
              get :message_api
              get :login_api
              get :webhook_modal
              get :callback_modal
            end

            collection do
              post :reset
            end

            resource :rich_menu, only: [:edit, :create, :destroy]
            resources :social_rich_menus, only: [:index, :new, :edit, :show, :destroy] do
              collection do
                post :upsert
                get :keyword_rich_menu_size
              end

              member do
                put :current
              end
            end
          end

          resources :business_schedules, only: [] do
            collection do
              put "/shop/:shop_id/update/:wday", action: :update, as: :update
              get :shops
              get "/shop/:shop_id", action: :index, as: :index
              get "/shop/:shop_id/edit/:wday", action: :edit, as: :edit
            end
          end

          resources :shops, only: [:index, :show, :update, :edit] do
            collection do
              get :custom_messages
            end

            resources :custom_messages, only: [:index] do
              collection do
                get "/:scenario(/:id)", action: "edit_scenario", as: :edit_scenario
              end
            end
          end

          resources :staffs do
            collection do
              get :resend_activation_sms
            end
          end
          resources :consultants, only: [:index, :new, :create] do
            collection do
              get :new_application
              post :create_application
            end
          end

          resources :menus do
            collection do
              get "/social_service_user_id/:social_service_user_id", action: "index"
            end
          end
        end

        resources :customers, only: [:index] do
          collection do
            get :details
            get :recent
            get :search
            get :find_duplicate_customers
            get :filter
            post :save
            delete :delete
            post :toggle_reminder_permission
            post :reply_message
            post :save_draft_message
            delete :delete_message
            put :unread_message
            get  "/data_changed/:reservation_customer_id", to: "customers#data_changed", as: :data_changed
            patch "/save_changes/:reservation_customer_id", to: "customers#save_changes", as: :save_changes
            get "/social_service_user_id/:social_service_user_id", action: "index"
            get :csv
          end
        end

        scope module: "customers", as: "customer", path: "customer" do
          resources :reservations, only: [:index] do
            collection do
              get "/:reservation_id/pend/:customer_id", action: :pend, as: :pend
              get "/:reservation_id/accept/:customer_id", action: :accept, as: :accept
              get "/:reservation_id/cancel/:customer_id", action: :cancel, as: :cancel
              get "/:reservation_id/refund_modal/:customer_id", action: :refund_modal, as: :refund_modal
              post "/:reservation_id/refund/:customer_id", action: :refund, as: :refund
              get "/:reservation_id/edit_ticket_modal/:customer_id", action: :edit_ticket_modal, as: :edit_ticket_modal
              post "/:reservation_id/update_ticket/:customer_id", action: :update_ticket, as: :update_ticket
            end
          end
          resources :messages, only: [:index]
          resources :payments, only: [:index] do
            member do
              get :refund_modal
              post :refund
            end
          end
        end

        resources :shops, only: [] do
          resources :reservations, except: [:index, :edit, :new] do
            collection do
              post :validate
              post :add_customer
              get :schedule
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

              resource :messages, only: [:new, :create]
            end
          end
        end

        resources :online_service_customer_relations, only: [:show]
        resources :custom_schedules, only: [:create, :update, :destroy]

        resources :warnings, only: [], constraints: ::XhrConstraint do
          collection do
            get :create_reservation
            get :create_course
            get :check_reservation_content
            get :over_free_limit
            get "/cancel_paid_customers/:reservation_id", action: "cancel_paid_customers", as: :cancel_paid_customers
            get :change_verified_line_settings
          end
        end

        scope module: :tours, path: :tours, as: :tours do
          get :line_settings_required_for_online_service
          get :line_settings_required_for_booking_page
        end
      end
      # business owner scope END

      resources :notifications, only: [:index] do
        collection do
          get "/social_service_user_id/:social_service_user_id", action: "index"
        end
      end

      resources :social_user_messages, only: [:new, :create]
    end
  end

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
        post :toggle_reminder_permission
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
      resources :messages, only: [:index]

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
    post "user_bot_line", to: "user_bot_lines#create", as: :user_bot_line
    post "tw_user_bot_line", to: "user_bot_lines#tw_create", as: :tw_user_bot_line
    post "stripe", to: "stripe#create", as: :stripe
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

  authenticated :user, -> user { user.super_admin? || user.can_admin_chat? || Rails.env.development? } do
    scope "(:locale)", locale: /tw|ja/, defaults: { locale: "ja" } do
      namespace :admin do
        resource :memo, only: [:create]
        resource :social_account, only: [:edit, :update, :destroy], param: :social_service_user_id do
          member do
            post :line_finished_message
          end
        end
        resources :chats, only: [:index, :create, :destroy]
        resources :sale_pages, only: [:index]
        resources :booking_pages, only: [:index]
        resources :online_service_customer_relations, only: [:index]
        resource :subscription, only: [:destroy]
        get "logs"

        resources :custom_messages, only: [] do
          collection do
            get "scenario/:scenario", action: "scenario", as: :scenario
            get "scenario/:scenario/new", action: "new", as: :new
            get "scenario/:scenario/edit/:id", action: "edit", as: :edit
            post "scenario/:scenario", action: "create", as: :create
            put "scenario/:scenario/:id", action: "update", as: :update
            get "scenarios", action: "scenarios"
            post "scenario/:scenario/demo", action: "demo", as: :demo
          end
        end
      end
    end
  end

  authenticated :user, -> user { user.super_admin? || Rails.env.development? } do
    mount Delayed::Web::Engine, at: "/_jobs"
    mount PgHero::Engine, at: "/_pghero"
    mount Blazer::Engine, at: "_blazer"
    mount DelayedJobWeb, at: "/_delayed_job"

    namespace :admin do
      get "as_user"
      get "/", to: "dashboards#index"

      resources :business_applications, only: [:index] do
        member do
          post "approve"
          post "reject"
        end
      end

      resources :ai, only: [:index, :create] do
        collection do
          post :correct
          post :incorrect
          post :build_by_url
          post :build_by_faq
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

  root to: "lines/user_bot/schedules#mine"

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
  resources :bookings, param: :slug, only: [:show, :destroy]
  resources :sale_pages, param: :slug, only: [:show]
  resources :online_services, param: :slug, only: [:show] do
    member do
      put "/lessons/:lesson_id", action: :watch_lesson, as: :watch_lesson
      put "/episodes/:episode_id", action: :watch_episode, as: :watch_episode
      get "/episodes(/:tag)", action: :tagged_episodes, as: :tagged_episodes
      get "/search/:keyword", action: :search_episodes, as: :search_episodes
      get "/customer_status/:encrypted_social_service_user_id", action: :customer_status, as: :customer_status

      scope module: :online_services do
        resources :customer_payments, only: [:create] do
          collection do
            get "/:encrypted_social_service_user_id/new(/:order_id)", action: :new, as: :new
            put :change_card
          end
        end
      end
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

  # Mount letter_opener web interface in development
  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
