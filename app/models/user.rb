# frozen_string_literal: true
# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  confirmation_sent_at         :datetime
#  confirmation_token           :string
#  confirmed_at                 :datetime
#  contacts_sync_at             :datetime
#  current_sign_in_at           :datetime
#  current_sign_in_ip           :inet
#  customer_latest_activity_at  :datetime
#  customers_count              :integer          default(0)
#  email                        :string
#  encrypted_password           :string           default(""), not null
#  failed_attempts              :integer          default(0), not null
#  last_sign_in_at              :datetime
#  last_sign_in_ip              :inet
#  locked_at                    :datetime
#  mixpanel_profile_last_set_at :datetime
#  phone_number                 :string
#  referral_token               :string
#  remember_created_at          :datetime
#  reset_password_sent_at       :datetime
#  reset_password_token         :string
#  sign_in_count                :integer          default(0), not null
#  unconfirmed_email            :string
#  unlock_token                 :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  public_id                    :uuid             not null
#
# Indexes
#
#  index_users_on_confirmation_token           (confirmation_token) UNIQUE
#  index_users_on_customer_latest_activity_at  (customer_latest_activity_at)
#  index_users_on_email                        (email) UNIQUE
#  index_users_on_phone_number                 (phone_number) UNIQUE
#  index_users_on_public_id                    (public_id) UNIQUE
#  index_users_on_referral_token               (referral_token) UNIQUE
#  index_users_on_reset_password_token         (reset_password_token) UNIQUE
#  index_users_on_unlock_token                 (unlock_token) UNIQUE
#

# @email, @phone_number represent how user sign up our service, @email is from web, @phone_number is from line
require "user_bot_social_account"
require "tw_user_bot_social_account"

class User < ApplicationRecord
  include SayHi

  HARUKO_EMAIL = "haruko_liu@dreamhint.com"
  ADMIN_EMAIL = "info@dreamhint.com"
  ADMIN_IDS = [1, 2, 5, 61, 813, 1053, 1072, 2584, 7006].freeze
  CHAT_OPERATOR_IDS = [1073].freeze

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :omniauthable

  has_many :access_providers
  has_one :access_provider, -> { where(provider: "google_oauth2")}, dependent: :destroy
  has_one :stripe_provider, -> { where(provider: "stripe_connect")}, dependent: :destroy, class_name: "AccessProvider"
  has_one :square_provider, -> { where(provider: "square")}, dependent: :destroy, class_name: "AccessProvider"
  has_one :payment_provider, -> { where(provider: AccessProvider::PAYMENT_PROVIDERS).where(default_payment: true) }, dependent: :destroy, class_name: "AccessProvider"
  has_many :payment_providers, -> { where(provider: AccessProvider::PAYMENT_PROVIDERS) }, dependent: :destroy, class_name: "AccessProvider"
  has_one :profile, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :reservations, -> { active }
  has_many :all_reservations, class_name: "Reservation"
  has_many :shops, -> { active }
  has_one :shop, -> { active.order("id") }
  has_many :menus, -> { active }
  has_many :staffs, -> { active }
  has_many :customers, -> { active }
  has_many :broadcasts
  has_many :reservation_settings
  has_many :categories
  has_many :ranks, dependent: :destroy
  has_many :contact_groups
  has_many :staff_accounts, foreign_key: :user_id
  has_many :owner_staff_accounts, class_name: "StaffAccount", foreign_key: :owner_id
  has_many :customer_query_filters
  has_many :reservation_query_filters
  has_many :filtered_outcomes
  has_many :subscription_charges do
    def last_completed
      where(state: :completed)
        .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_reservation])
        .where.not("details ->> 'type' = ?", SubscriptionCharge::TYPES[:downgrade_cancellation])
        .order("updated_at")
        .last
    end

    def last_plan_charged
      where("details ->> 'type' = ?", SubscriptionCharge::TYPES[:plan_subscruption]).last_completed
    end
  end
  has_many :custom_schedules, dependent: :destroy
  has_many :booking_options, -> { undeleted }
  has_many :all_booking_options, class_name: "BookingOption"
  has_many :booking_pages, -> { active }
  has_many :referrals, foreign_key: :referee_id
  has_one :reference, foreign_key: :referrer_id, class_name: "Referral"
  has_many :payments, foreign_key: :receiver_id
  has_many :payment_withdrawals, foreign_key: :receiver_id
  has_many :social_accounts
  has_one :social_account, -> { order("id") }
  has_many :social_customers
  has_one :owner_social_customer, -> { where(is_owner: true) }, class_name: "SocialCustomer"
  has_one :business_application
  has_one :social_user
  has_one :user_metric
  has_one :user_setting
  has_many :web_push_subscriptions
  has_many :sale_pages, -> { active }
  has_many :all_sale_pages, class_name: "SalePage"
  has_many :online_services
  has_many :tickets
  has_many :surveys
  has_many :line_notice_requests, dependent: :destroy
  has_many :line_notice_charges, dependent: :destroy

  delegate :access_token, :refresh_token, :uid, to: :access_provider, allow_nil: true
  delegate :name, :company_name, :last_name, :first_name, :phonetic_last_name, :phonetic_first_name, :display_last_name, :display_first_name, :message_name, to: :profile, allow_nil: true
  delegate :current_plan, :trial_expired_date, to: :subscription
  delegate :social_service_user_id, to: :social_user, allow_nil: true
  delegate :square_client, to: :square_provider
  delegate :line_keyword_booking_page_ids, :line_keyword_booking_option_ids, :line_contact_customer_name_required, :customer_tags, :toruya_message_reply, :booking_options_menu_concept, :customer_notification_channel, :schedule_mode, to: :user_setting, allow_nil: true

  scope :admin, -> { joins(:social_user).where(social_service_user_id: SocialUser::ADMIN_IDS) }
  scope :not_admin, -> { where.not.admin }
  scope :business_active, -> (period = 1.month.ago..Time.current) { where(customer_latest_activity_at: period) }

  before_validation(on: :create) do
    self.public_id ||= SecureRandom.uuid
  end

  def super_admin?
    ADMIN_IDS.include?(id) || social_user&.super_admin?
  end

  def can_admin_chat?
    super_admin? || CHAT_OPERATOR_IDS.include?(id)
  end

  # shop owner or staffs
  def member?
    true
  end

  def member_plan
    return @plan if defined?(@plan)

    @plan = current_plan.level

    if @plan == Plan::FREE_PLAN && Subscription.today < trial_expired_date
      @plan = Plan::TRIAL_PLAN
    else
      @plan
    end
  end
  alias_method :member_plan_key, :member_plan

  def permission_level
    Plan.permission_level(member_plan_key)
  end

  def member_plan_name
    I18n.t("plan.level.#{member_plan_key}")
  end

  def current_staff_account(super_user = nil)
    super_user ||= Current.business_owner
    super_user ||= Current.user
    super_user ||= self
    @current_staff_accounts ||= {}

    return @current_staff_accounts[super_user] if @current_staff_accounts[super_user]

    @current_staff_accounts[super_user] = super_user.owner_staff_accounts.active.find_by(user_id: self.id)
  end

  def current_staff(super_user = nil)
    super_user ||= Current.business_owner
    super_user ||= self
    @current_staffs ||= {}

    return @current_staffs[super_user] if @current_staffs[super_user]

    @current_staffs[super_user] = current_staff_account(super_user).try(:staff)
  end

  def trial_member?
    permission_level == Plan::TRIAL_LEVEL
  end

  def premium_member?
    permission_level == Plan::PREMIUM_LEVEL
  end

  def child_plan_member?
    reference&.pending? || active_child_member?
  end

  def active_child_member?
    Plan::CHILD_PLANS.include?(member_plan_key)
  end

  def business_member?
    member_plan == Plan::BUSINESS_PLAN
  end

  def support_toruya_message_reply?
    (premium_member? || trial_member?) && subscription.active?
  end

  def valid_shop_ids
    @valid_shop_ids ||=
      if true || premium_member?
        # XXX: Since we don't support multiple features for now, we allow users to use all the shop they own now
        # this permission need to re-think when we introudce the shop management feature
        shop_ids
      else
        shop_ids.sort.slice(0, 1)
      end
  end

  def has_invalid_shops?
    valid_shop_ids != shop_ids
  end

  def today_reservations_count
    @today_reservations_count ||= today_reservations.count
  end

  def total_reservations_count
    @total_reservations_count ||= total_reservations.count
  end

  def google_user
    # @google_user ||=
    #   if access_token && refresh_token
    #     GoogleContactsApi::User.new(access_token, refresh_token)
    #   end
  end

  def owner_ability
    Ability.new(self, self)
  end

  def payable?
    stripe_provider&.publishable_key.present?
  end

  def message_template_variables
    {
      plan_url: Rails.application.routes.url_helpers.lines_user_bot_settings_plans_url(business_owner_id: id, encrypted_user_id: MessageEncryptor.encrypt(id, expires_at: 2.week.from_now))
    }
  end

  def hi_message
    referral = Referral.find_by(referrer: self)

    if referral
      "👩 New user joined, user_id: #{id} from #{referral.referee.referral_token}"
    else
      "👩 New user joined, user_id: #{id}"
    end
  end

  def pending_reservations
    reservation_scope = Reservation.includes(reservation_customers: :customer).where(user_id: id).where("reservations.start_time > ?", 1.day.ago).where("reservations.deleted_at": nil)
    reservation_scope.where("reservations.aasm_state": :pending, "reservations.deleted_at": nil).or(
      reservation_scope.where("reservation_customers.state": "pending").where("customers.deleted_at": nil)
    ).order("reservations.start_time ASC, reservations.id ASC").distinct
  end

  def missing_sale_page_services
    # missing_sale_page_service_ids = online_services.pluck(:id) - all_sale_pages.where(product_type: "OnlineService").pluck(:product_id)
    # online_services.where(id: missing_sale_page_service_ids)
    online_services.none
  end

  def pending_customer_services
    online_services.external.joins(:handle_required_online_service_customer_relations).select("id", "internal_name", "name", "goal_type", "user_id").distinct
  end

  def line_keyword_booking_pages
    booking_pages.active.normal.where(id: line_keyword_booking_page_ids).sort_by { |page| line_keyword_booking_page_ids.index(page.id.to_s) }
  end

  def related_users
    social_user&.current_users
  end

  def related_user_ids
    @related_user_ids ||= related_users&.map(&:id) || []
  end

  def all_staff_related_users
    owner_staff_accounts.active.map(&:user).map(&:related_users).flatten.compact.uniq
  end

  def line_keyword_booking_options
    booking_options.where(id: line_keyword_booking_option_ids).sort_by { |option| line_keyword_booking_option_ids.index(option.id.to_s) }
  end

  def line_keyword_booking_options_page
    booking_pages.active.for_option_in_rich_menu.includes(:booking_page_options).select do |page|
      line_keyword_booking_option_ids.include?(page.booking_page_options.first.booking_option_id.to_s)
    end.sort_by do |page|
      line_keyword_booking_option_ids.index(page.booking_page_options.first.booking_option_id.to_s)
    end
  end

  def self.currency
    case I18n.locale
    when "tw", :tw
      "TWD"
    else
      Money.default_currency.iso_code
    end
  end

  def currency
    case locale
    when "ja", :ja
      Money.default_currency.iso_code
    when "tw", :tw
      "TWD"
    else
      Money.default_currency.iso_code
    end
  end

  def locale
    I18n.available_locales.include?(social_user&.locale&.to_sym) ? social_user&.locale.to_sym : I18n.default_locale
  end

  def locale_is?(_locale)
    locale.to_sym == _locale
  end

  def prefer_line_login?
    customer_notification_channel == "line"
  end

  def timezone
    ::LOCALE_TIME_ZONE[locale] || "Asia/Tokyo"
  end

  def fallback_email
    email.presence || social_user&.email
  end

  # Returns true if there are customer messages from any customer to the same user for m consecutive days within the past n days
  def customer_message_in_a_row?(n, m)
    # Get the date range for the past n days (excluding today)
    date_range = (1..n).map { |i| i.days.ago.to_date }

    customer_messages = SocialMessage.where(
      user_id: id,
      message_type: SocialMessage.message_types[:customer],
      created_at: n.days.ago.beginning_of_day..Time.current
    )

    # Group messages by date and get the list of dates with messages
    messages_by_date = customer_messages.group_by { |msg| msg.created_at.to_date }
    message_dates = date_range.select { |date| messages_by_date[date]&.any? }

    # Check if there are at least m days with messages
    return false if message_dates.length < m

    # Sort dates and check for consecutiveness
    sorted_dates = message_dates.sort
    (0..sorted_dates.length - m).any? do |i|
      consecutive_dates = sorted_dates[i, m]
      # Check if these m dates are consecutive
      consecutive_dates.each_cons(2).all? { |prev, curr| (curr - prev).to_i == 1 }
    end
  end

  def has_single_shop?
    shops.count == 1
  end

  # LINE通知関連メソッド
  def line_notice_free_trial_available?
    !line_notice_charges.free_trials.successful.exists?
  end

  def line_notice_free_trial_used?
    line_notice_charges.free_trials.successful.exists?
  end

  def line_notice_charges_count
    line_notice_charges.successful.count
  end

  def line_notice_free_trial_count
    line_notice_charges.free_trials.successful.count
  end

  def line_notice_paid_charges_count
    line_notice_charges.paid_charges.successful.count
  end

  private

  def today_reservations
    reservations.where(created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
  end

  def total_reservations
    reservations.active
  end
end
