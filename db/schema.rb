# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_01_09_234255) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_stat_statements"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "access_providers", id: :serial, force: :cascade do |t|
    t.string "access_token"
    t.string "refresh_token"
    t.string "provider"
    t.string "uid"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.index ["provider", "uid"], name: "index_access_providers_on_provider_and_uid"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "booking_codes", force: :cascade do |t|
    t.string "uuid"
    t.string "code"
    t.integer "booking_page_id"
    t.integer "customer_id"
    t.integer "reservation_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.string "phone_number"
    t.index ["booking_page_id", "uuid", "code"], name: "index_booking_codes_on_booking_page_id_and_uuid_and_code", unique: true
  end

  create_table "booking_option_menus", force: :cascade do |t|
    t.bigint "booking_option_id", null: false
    t.bigint "menu_id", null: false
    t.integer "priority"
    t.integer "required_time"
    t.index ["booking_option_id"], name: "index_booking_option_menus_on_booking_option_id"
    t.index ["menu_id"], name: "index_booking_option_menus_on_menu_id"
  end

  create_table "booking_options", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "display_name"
    t.integer "minutes", null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", null: false
    t.boolean "tax_include", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "menu_restrict_order", default: false, null: false
    t.index ["user_id"], name: "index_booking_options_on_user_id"
  end

  create_table "booking_page_options", force: :cascade do |t|
    t.bigint "booking_page_id", null: false
    t.bigint "booking_option_id", null: false
    t.index ["booking_option_id"], name: "index_booking_page_options_on_booking_option_id"
    t.index ["booking_page_id"], name: "index_booking_page_options_on_booking_page_id"
  end

  create_table "booking_page_special_dates", force: :cascade do |t|
    t.bigint "booking_page_id", null: false
    t.datetime "start_at", null: false
    t.datetime "end_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_page_id"], name: "index_booking_page_special_dates_on_booking_page_id"
  end

  create_table "booking_pages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "shop_id", null: false
    t.string "name", null: false
    t.string "title"
    t.text "greeting"
    t.text "note"
    t.integer "interval"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_at"
    t.datetime "end_at"
    t.boolean "overbooking_restriction", default: true
    t.boolean "draft", default: true, null: false
    t.integer "booking_limit_day", default: 1, null: false
    t.boolean "line_sharing", default: true
    t.index ["shop_id"], name: "index_booking_pages_on_shop_id"
    t.index ["user_id", "draft", "line_sharing", "start_at"], name: "booking_page_index"
    t.index ["user_id"], name: "index_booking_pages_on_user_id"
  end

  create_table "business_applications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_business_applications_on_user_id"
  end

  create_table "business_schedules", id: :serial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "staff_id"
    t.boolean "full_time"
    t.string "business_state"
    t.integer "day_of_week"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "business_state", "day_of_week", "start_time", "end_time"], name: "shop_working_time_index"
    t.index ["shop_id", "staff_id", "full_time", "business_state", "day_of_week", "start_time", "end_time"], name: "staff_working_time_index"
  end

  create_table "categories", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id"
  end

  create_table "contact_group_rankings", id: :serial, force: :cascade do |t|
    t.integer "contact_group_id"
    t.integer "rank_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_group_id"], name: "index_contact_group_rankings_on_contact_group_id"
    t.index ["rank_id"], name: "index_contact_group_rankings_on_rank_id"
  end

  create_table "contact_groups", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "google_uid"
    t.string "google_group_name"
    t.string "google_group_id"
    t.string "backup_google_group_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "bind_all"
    t.index ["user_id", "bind_all"], name: "index_contact_groups_on_user_id_and_bind_all", unique: true
    t.index ["user_id", "google_uid", "google_group_id", "backup_google_group_id"], name: "contact_groups_google_index", unique: true
  end

  create_table "custom_schedules", id: :serial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "staff_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "open", default: false, null: false
    t.integer "user_id"
    t.index ["shop_id", "open", "start_time", "end_time"], name: "shop_custom_schedules_index"
    t.index ["staff_id", "open", "start_time", "end_time"], name: "staff_custom_schedules_index"
    t.index ["user_id", "open", "start_time", "end_time"], name: "personal_schedule_index"
  end

  create_table "customers", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "contact_group_id"
    t.integer "rank_id"
    t.string "last_name"
    t.string "first_name"
    t.string "phonetic_last_name"
    t.string "phonetic_first_name"
    t.string "custom_id"
    t.text "memo"
    t.string "address"
    t.string "google_uid"
    t.string "google_contact_id"
    t.string "google_contact_group_ids", default: [], array: true
    t.date "birthday"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "updated_by_user_id"
    t.string "email_types"
    t.datetime "deleted_at"
    t.boolean "reminder_permission", default: false
    t.jsonb "phone_numbers_details", default: []
    t.jsonb "emails_details", default: []
    t.jsonb "address_details", default: {}
    t.index ["first_name"], name: "customer_names_on_first_name_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["last_name"], name: "customer_names_on_last_name_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["phonetic_first_name"], name: "customer_names_on_phonetic_first_name_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["phonetic_last_name"], name: "customer_names_on_phonetic_last_name_idx", opclass: :gin_trgm_ops, using: :gin
    t.index ["user_id", "contact_group_id", "deleted_at"], name: "customers_basic_index"
    t.index ["user_id", "google_uid", "google_contact_id"], name: "customers_google_index", unique: true
    t.index ["user_id", "phonetic_last_name", "phonetic_first_name"], name: "jp_name_index"
  end

  create_table "delayed_jobs", id: :serial, force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "filtered_outcomes", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "filter_id"
    t.jsonb "query"
    t.string "file"
    t.string "page_size"
    t.string "outcome_type"
    t.string "aasm_state", null: false
    t.datetime "created_at"
    t.string "name"
    t.index ["user_id", "aasm_state", "outcome_type", "created_at"], name: "filtered_outcome_index"
  end

  create_table "menu_categories", id: :serial, force: :cascade do |t|
    t.integer "menu_id"
    t.integer "category_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "category_id"], name: "index_menu_categories_on_menu_id_and_category_id"
  end

  create_table "menu_reservation_setting_rules", id: :serial, force: :cascade do |t|
    t.integer "menu_id"
    t.string "reservation_type"
    t.date "start_date"
    t.date "end_date"
    t.integer "repeats"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id", "reservation_type", "start_date", "end_date"], name: "menu_reservation_setting_rules_index"
  end

  create_table "menus", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "short_name"
    t.integer "minutes"
    t.integer "interval"
    t.integer "min_staffs_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["user_id", "deleted_at"], name: "index_menus_on_user_id_and_deleted_at"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "user_id"
    t.string "phone_number"
    t.text "content"
    t.integer "customer_id"
    t.integer "reservation_id"
    t.boolean "charged", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "charged"], name: "index_notifications_on_user_id_and_charged"
  end

  create_table "payment_withdrawals", force: :cascade do |t|
    t.integer "receiver_id", null: false
    t.integer "state", default: 0, null: false
    t.decimal "amount_cents", null: false
    t.string "amount_currency", null: false
    t.string "order_id"
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "payment_withdrawal_order_index", unique: true
    t.index ["receiver_id", "state", "amount_cents", "amount_currency"], name: "payment_withdrawal_receiver_state_index"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "receiver_id", null: false
    t.integer "referrer_id"
    t.integer "payment_withdrawal_id"
    t.integer "charge_id"
    t.decimal "amount_cents", null: false
    t.string "amount_currency", null: false
    t.jsonb "details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["receiver_id"], name: "payment_receiver_index"
  end

  create_table "pghero_query_stats", force: :cascade do |t|
    t.text "database"
    t.text "user"
    t.text "query"
    t.bigint "query_hash"
    t.float "total_time"
    t.bigint "calls"
    t.datetime "captured_at"
    t.index ["database", "captured_at"], name: "index_pghero_query_stats_on_database_and_captured_at"
  end

  create_table "plans", force: :cascade do |t|
    t.integer "position"
    t.integer "level"
  end

  create_table "profiles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "first_name"
    t.string "last_name"
    t.string "phonetic_first_name"
    t.string "phonetic_last_name"
    t.string "company_name"
    t.string "zip_code"
    t.string "address"
    t.string "phone_number"
    t.string "website"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_zip_code"
    t.string "company_address"
    t.string "company_phone_number"
    t.string "email"
    t.string "region"
    t.string "city"
    t.string "street1"
    t.string "street2"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "query_filters", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.jsonb "query"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_query_filters_on_user_id"
  end

  create_table "ranks", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name", null: false
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ranks_on_user_id"
  end

  create_table "referrals", force: :cascade do |t|
    t.integer "referrer_id", null: false
    t.integer "referee_id", null: false
    t.integer "state", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["referrer_id"], name: "index_referrals_on_referrer_id", unique: true
  end

  create_table "reservation_booking_options", force: :cascade do |t|
    t.bigint "reservation_id"
    t.bigint "booking_option_id"
    t.index ["booking_option_id"], name: "index_reservation_booking_options_on_booking_option_id"
    t.index ["reservation_id"], name: "index_reservation_booking_options_on_reservation_id"
  end

  create_table "reservation_customers", id: :serial, force: :cascade do |t|
    t.integer "reservation_id", null: false
    t.integer "customer_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "booking_page_id"
    t.integer "booking_option_id"
    t.integer "state", default: 0
    t.string "booking_amount_currency"
    t.decimal "booking_amount_cents"
    t.boolean "tax_include"
    t.datetime "booking_at"
    t.jsonb "details"
    t.index ["reservation_id", "customer_id"], name: "index_reservation_customers_on_reservation_id_and_customer_id", unique: true
  end

  create_table "reservation_menus", force: :cascade do |t|
    t.bigint "reservation_id"
    t.bigint "menu_id"
    t.integer "position"
    t.integer "required_time"
    t.index ["menu_id"], name: "index_reservation_menus_on_menu_id"
    t.index ["reservation_id", "menu_id"], name: "reservation_menu_index"
  end

  create_table "reservation_setting_menus", id: :serial, force: :cascade do |t|
    t.integer "reservation_setting_id"
    t.integer "menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["reservation_setting_id", "menu_id"], name: "reservation_setting_menus_index"
  end

  create_table "reservation_settings", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "short_name"
    t.string "day_type"
    t.integer "day"
    t.integer "nth_of_week"
    t.string "days_of_week", default: [], array: true
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "start_time", "end_time", "day_type", "days_of_week", "day", "nth_of_week"], name: "reservation_setting_index"
  end

  create_table "reservation_staffs", id: :serial, force: :cascade do |t|
    t.integer "reservation_id", null: false
    t.integer "staff_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "state", default: 0
    t.integer "menu_id"
    t.datetime "prepare_time"
    t.datetime "work_start_at"
    t.datetime "work_end_at"
    t.datetime "ready_time"
    t.index ["reservation_id", "menu_id", "staff_id", "prepare_time", "work_start_at", "work_end_at", "ready_time"], name: "reservation_staff_index"
    t.index ["staff_id", "state"], name: "state_by_staff_id_index"
  end

  create_table "reservations", id: :serial, force: :cascade do |t|
    t.integer "shop_id", null: false
    t.integer "menu_id"
    t.datetime "start_time", null: false
    t.datetime "end_time", null: false
    t.datetime "ready_time", null: false
    t.string "aasm_state", null: false
    t.text "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "count_of_customers", default: 0
    t.boolean "with_warnings", default: false, null: false
    t.integer "by_staff_id"
    t.datetime "deleted_at"
    t.datetime "prepare_time"
    t.integer "user_id"
    t.index ["user_id", "shop_id", "aasm_state", "menu_id", "start_time", "ready_time"], name: "reservation_query_index"
    t.index ["user_id", "shop_id", "deleted_at"], name: "reservation_user_shop_index"
  end

  create_table "sale_pages", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "staff_id"
    t.string "product_type", null: false
    t.bigint "product_id", null: false
    t.bigint "sale_template_id"
    t.json "sale_template_variables"
    t.json "content"
    t.json "flow"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_type", "product_id"], name: "index_sale_pages_on_product_type_and_product_id"
    t.index ["sale_template_id"], name: "index_sale_pages_on_sale_template_id"
    t.index ["staff_id"], name: "index_sale_pages_on_staff_id"
    t.index ["user_id"], name: "index_sale_pages_on_user_id"
  end

  create_table "sale_templates", force: :cascade do |t|
    t.json "edit_body"
    t.json "view_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shop_menu_repeating_dates", id: :serial, force: :cascade do |t|
    t.integer "shop_id", null: false
    t.integer "menu_id", null: false
    t.string "dates", default: [], array: true
    t.date "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["menu_id"], name: "index_shop_menu_repeating_dates_on_menu_id"
    t.index ["shop_id", "menu_id"], name: "index_shop_menu_repeating_dates_on_shop_id_and_menu_id", unique: true
  end

  create_table "shop_menus", id: :serial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_seat_number"
    t.index ["shop_id", "menu_id"], name: "index_shop_menus_on_shop_id_and_menu_id", unique: true
  end

  create_table "shop_staffs", id: :serial, force: :cascade do |t|
    t.integer "shop_id"
    t.integer "staff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "staff_regular_working_day_permission", default: false, null: false
    t.boolean "staff_temporary_working_day_permission", default: false, null: false
    t.boolean "staff_full_time_permission", default: false, null: false
    t.integer "level", default: 0, null: false
    t.index ["shop_id", "staff_id"], name: "index_shop_staffs_on_shop_id_and_staff_id", unique: true
  end

  create_table "shops", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "name", null: false
    t.string "short_name", null: false
    t.string "zip_code", null: false
    t.string "phone_number"
    t.string "email"
    t.string "address", null: false
    t.string "website"
    t.boolean "holiday_working"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.json "template_variables"
    t.index ["user_id", "deleted_at"], name: "index_shops_on_user_id_and_deleted_at"
  end

  create_table "social_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "channel_id"
    t.string "channel_token"
    t.string "channel_secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "label"
    t.string "basic_id"
    t.index ["user_id", "channel_id"], name: "index_social_accounts_on_user_id_and_channel_id", unique: true
  end

  create_table "social_customers", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "customer_id"
    t.integer "social_account_id"
    t.string "social_user_id", null: false
    t.string "social_user_name"
    t.string "social_user_picture_url"
    t.integer "conversation_state", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "social_rich_menu_key"
    t.index ["customer_id"], name: "index_social_customers_on_customer_id"
    t.index ["social_rich_menu_key"], name: "index_social_customers_on_social_rich_menu_key"
    t.index ["user_id", "social_account_id", "social_user_id"], name: "social_customer_unique_index", unique: true
    t.index ["user_id"], name: "index_social_customers_on_user_id"
  end

  create_table "social_messages", force: :cascade do |t|
    t.integer "social_account_id", null: false
    t.integer "social_customer_id", null: false
    t.integer "staff_id"
    t.text "raw_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "readed_at"
    t.integer "message_type", default: 0
    t.index ["social_account_id", "social_customer_id"], name: "social_message_customer_index"
  end

  create_table "social_rich_menus", force: :cascade do |t|
    t.integer "social_account_id"
    t.string "social_rich_menu_id"
    t.string "social_name"
    t.index ["social_account_id", "social_name"], name: "index_social_rich_menus_on_social_account_id_and_social_name"
  end

  create_table "social_user_messages", force: :cascade do |t|
    t.integer "social_user_id", null: false
    t.integer "admin_user_id"
    t.integer "message_type"
    t.datetime "readed_at"
    t.text "raw_content"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["social_user_id"], name: "social_user_message_index"
  end

  create_table "social_users", force: :cascade do |t|
    t.bigint "user_id"
    t.string "social_service_user_id", null: false
    t.string "social_user_name"
    t.string "social_user_picture_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "social_rich_menu_key"
    t.index ["social_rich_menu_key"], name: "index_social_users_on_social_rich_menu_key"
    t.index ["user_id", "social_service_user_id"], name: "social_user_unique_index", unique: true
    t.index ["user_id"], name: "index_social_users_on_user_id"
  end

  create_table "staff_accounts", id: :serial, force: :cascade do |t|
    t.string "email"
    t.integer "user_id"
    t.integer "owner_id", null: false
    t.integer "staff_id", null: false
    t.string "token"
    t.integer "state", default: 0, null: false
    t.integer "level", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active_uniqueness"
    t.string "phone_number"
    t.index ["owner_id", "email"], name: "staff_account_email_index"
    t.index ["owner_id", "phone_number"], name: "index_staff_accounts_on_owner_id_and_phone_number", unique: true
    t.index ["owner_id", "user_id", "active_uniqueness"], name: "unique_staff_account_index", unique: true
    t.index ["staff_id"], name: "index_staff_accounts_on_staff_id"
    t.index ["token"], name: "staff_account_token_index"
    t.index ["user_id"], name: "index_staff_accounts_on_user_id"
  end

  create_table "staff_contact_group_relations", force: :cascade do |t|
    t.bigint "staff_id", null: false
    t.bigint "contact_group_id", null: false
    t.integer "contact_group_read_permission", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_group_id"], name: "index_staff_contact_group_relations_on_contact_group_id"
    t.index ["staff_id", "contact_group_id"], name: "staff_contact_group_unique_index", unique: true
  end

  create_table "staff_menus", id: :serial, force: :cascade do |t|
    t.integer "staff_id", null: false
    t.integer "menu_id", null: false
    t.integer "max_customers"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "priority"
    t.index ["staff_id", "menu_id"], name: "index_staff_menus_on_staff_id_and_menu_id", unique: true
  end

  create_table "staffs", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "last_name"
    t.string "first_name"
    t.string "phonetic_last_name"
    t.string "phonetic_first_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.boolean "staff_holiday_permission", default: false, null: false
    t.text "introduction"
    t.index ["user_id", "deleted_at"], name: "index_staffs_on_user_id_and_deleted_at"
  end

  create_table "subscription_charges", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "plan_id"
    t.decimal "amount_cents"
    t.string "amount_currency"
    t.integer "state", default: 0, null: false
    t.date "charge_date"
    t.date "expired_date"
    t.boolean "manual", default: false, null: false
    t.jsonb "stripe_charge_details"
    t.string "order_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "details"
    t.index "((details ->> 'type'::text))", name: "subscription_charge_type_index"
    t.index ["order_id"], name: "order_id_index"
    t.index ["plan_id"], name: "index_subscription_charges_on_plan_id"
    t.index ["user_id", "state"], name: "user_state_index"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "plan_id"
    t.integer "next_plan_id"
    t.bigint "user_id"
    t.string "stripe_customer_id"
    t.integer "recurring_day"
    t.date "expired_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["user_id"], name: "index_subscriptions_on_user_id", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "contacts_sync_at"
    t.string "referral_token"
    t.string "phone_number"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["referral_token"], name: "index_users_on_referral_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object"
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "web_push_subscriptions", force: :cascade do |t|
    t.bigint "user_id"
    t.string "endpoint"
    t.string "p256dh_key"
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_web_push_subscriptions_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "profiles", "users"
end
