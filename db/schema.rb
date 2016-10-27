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

ActiveRecord::Schema.define(version: 20161027141005) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_providers", force: :cascade do |t|
    t.string   "access_token"
    t.string   "refresh_token"
    t.string   "provider"
    t.string   "uid"
    t.integer  "user_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["provider", "uid"], name: "index_access_providers_on_provider_and_uid", using: :btree
  end

  create_table "business_schedules", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "staff_id"
    t.boolean  "full_time"
    t.string   "business_state"
    t.integer  "day_of_week"
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["shop_id", "business_state", "day_of_week", "start_time", "end_time"], name: "shop_working_time_index", using: :btree
    t.index ["shop_id", "staff_id", "full_time", "business_state", "day_of_week", "start_time", "end_time"], name: "staff_working_time_index", using: :btree
  end

  create_table "categories", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "short_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_categories_on_user_id", using: :btree
  end

  create_table "contact_groups", force: :cascade do |t|
    t.integer  "user_id",                null: false
    t.string   "google_uid"
    t.string   "google_group_name"
    t.string   "google_group_id"
    t.string   "backup_google_group_id"
    t.string   "name",                   null: false
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["user_id", "google_uid", "google_group_id", "backup_google_group_id"], name: "contact_groups_google_index", unique: true, using: :btree
    t.index ["user_id"], name: "index_contact_groups_on_user_id", using: :btree
  end

  create_table "custom_schedules", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "staff_id"
    t.datetime "start_time"
    t.datetime "end_time"
    t.text     "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "staff_id", "start_time", "end_time"], name: "custom_schedules_index", using: :btree
  end

  create_table "customers", force: :cascade do |t|
    t.integer  "user_id",                               null: false
    t.integer  "contact_group_id"
    t.string   "last_name"
    t.string   "first_name"
    t.string   "phonetic_last_name"
    t.string   "phonetic_first_name"
    t.string   "address"
    t.string   "google_uid"
    t.string   "google_contact_id"
    t.string   "google_contact_group_ids", default: [],              array: true
    t.date     "birthday"
    t.datetime "created_at",                            null: false
    t.datetime "updated_at",                            null: false
    t.index ["contact_group_id"], name: "index_customers_on_contact_group_id", using: :btree
    t.index ["user_id", "google_uid", "google_contact_id"], name: "customers_google_index", unique: true, using: :btree
    t.index ["user_id", "phonetic_last_name", "phonetic_first_name"], name: "jp_name_index", using: :btree
    t.index ["user_id"], name: "index_customers_on_user_id", using: :btree
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",   default: 0, null: false
    t.integer  "attempts",   default: 0, null: false
    t.text     "handler",                null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority", using: :btree
  end

  create_table "menu_categories", force: :cascade do |t|
    t.integer  "menu_id"
    t.integer  "category_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
    t.index ["menu_id", "category_id"], name: "index_menu_categories_on_menu_id_and_category_id", using: :btree
  end

  create_table "menu_reservation_setting_rules", force: :cascade do |t|
    t.integer  "menu_id"
    t.string   "reservation_type"
    t.date     "start_date"
    t.date     "end_date"
    t.integer  "repeats"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.index ["menu_id", "reservation_type", "start_date", "end_date"], name: "menu_reservation_setting_rules_index", using: :btree
  end

  create_table "menus", force: :cascade do |t|
    t.integer  "user_id",           null: false
    t.string   "name",              null: false
    t.string   "shortname"
    t.integer  "minutes"
    t.integer  "interval"
    t.integer  "min_staffs_number"
    t.integer  "max_seat_number"
    t.datetime "created_at",        null: false
    t.datetime "updated_at",        null: false
    t.index ["user_id"], name: "index_menus_on_user_id", using: :btree
  end

  create_table "ranks", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ranks_on_user_id", using: :btree
  end

  create_table "reservation_customers", force: :cascade do |t|
    t.integer  "reservation_id", null: false
    t.integer  "customer_id",    null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["reservation_id", "customer_id"], name: "index_reservation_customers_on_reservation_id_and_customer_id", unique: true, using: :btree
  end

  create_table "reservation_setting_menus", force: :cascade do |t|
    t.integer  "reservation_setting_id"
    t.integer  "menu_id"
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
    t.index ["reservation_setting_id", "menu_id"], name: "reservation_setting_menus_index", using: :btree
  end

  create_table "reservation_settings", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "short_name"
    t.string   "day_type"
    t.integer  "day"
    t.integer  "nth_of_week"
    t.string   "days_of_week", default: [],              array: true
    t.datetime "start_time"
    t.datetime "end_time"
    t.datetime "created_at",                null: false
    t.datetime "updated_at",                null: false
    t.index ["user_id", "start_time", "end_time", "day_type", "days_of_week", "day", "nth_of_week"], name: "reservation_setting_index", using: :btree
  end

  create_table "reservation_staffs", force: :cascade do |t|
    t.integer  "reservation_id", null: false
    t.integer  "staff_id",       null: false
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
    t.index ["reservation_id", "staff_id"], name: "index_reservation_staffs_on_reservation_id_and_staff_id", unique: true, using: :btree
  end

  create_table "reservations", force: :cascade do |t|
    t.integer  "shop_id",    null: false
    t.integer  "menu_id",    null: false
    t.datetime "start_time", null: false
    t.datetime "end_time",   null: false
    t.datetime "ready_time", null: false
    t.string   "aasm_state", null: false
    t.text     "memo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "aasm_state", "menu_id", "start_time", "ready_time"], name: "reservation_index", using: :btree
  end

  create_table "shop_menu_repeating_dates", force: :cascade do |t|
    t.integer  "shop_id",                 null: false
    t.integer  "menu_id",                 null: false
    t.string   "dates",      default: [],              array: true
    t.date     "end_date"
    t.datetime "created_at",              null: false
    t.datetime "updated_at",              null: false
    t.index ["menu_id"], name: "index_shop_menu_repeating_dates_on_menu_id", using: :btree
    t.index ["shop_id", "menu_id"], name: "index_shop_menu_repeating_dates_on_shop_id_and_menu_id", unique: true, using: :btree
    t.index ["shop_id"], name: "index_shop_menu_repeating_dates_on_shop_id", using: :btree
  end

  create_table "shop_menus", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "menu_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "menu_id"], name: "index_shop_menus_on_shop_id_and_menu_id", unique: true, using: :btree
  end

  create_table "shop_staffs", force: :cascade do |t|
    t.integer  "shop_id"
    t.integer  "staff_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["shop_id", "staff_id"], name: "index_shop_staffs_on_shop_id_and_staff_id", unique: true, using: :btree
  end

  create_table "shops", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "name",         null: false
    t.string   "shortname",    null: false
    t.string   "zip_code",     null: false
    t.string   "phone_number", null: false
    t.string   "email",        null: false
    t.string   "address",      null: false
    t.string   "website"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
    t.index ["user_id"], name: "index_shops_on_user_id", using: :btree
  end

  create_table "staff_menus", force: :cascade do |t|
    t.integer  "staff_id",      null: false
    t.integer  "menu_id",       null: false
    t.integer  "max_customers"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.index ["staff_id", "menu_id"], name: "index_staff_menus_on_staff_id_and_menu_id", unique: true, using: :btree
  end

  create_table "staffs", force: :cascade do |t|
    t.integer  "user_id",             null: false
    t.string   "last_name"
    t.string   "first_name"
    t.string   "phonetic_last_name"
    t.string   "phonetic_first_name"
    t.datetime "created_at",          null: false
    t.datetime "updated_at",          null: false
    t.index ["user_id"], name: "index_staffs_on_user_id", using: :btree
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.string   "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string   "unconfirmed_email"
    t.integer  "failed_attempts",        default: 0,  null: false
    t.string   "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true, using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true, using: :btree
  end

end
