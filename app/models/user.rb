# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  contacts_sync_at       :datetime
#  referral_token         :string
#
# Indexes
#
#  index_users_on_confirmation_token    (confirmation_token) UNIQUE
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_referral_token        (referral_token) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :omniauthable

  has_one :access_provider, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :shops, -> { active }
  has_many :menus, -> { active }
  has_many :staffs, -> { active }
  has_many :customers, -> { active }
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
      where(state: :completed).order("updated_at").last
    end
  end
  has_many :custom_schedules, dependent: :destroy
  has_many :booking_options
  has_many :booking_pages
  has_many :referrals, foreign_key: :referee_id
  has_one :reference, foreign_key: :referrer_id, class_name: "Referral"
  has_many :payments, foreign_key: :receiver_id
  has_many :payment_withdrawals, foreign_key: :receiver_id
  has_one :business_application

  delegate :access_token, :refresh_token, :uid, to: :access_provider, allow_nil: true
  delegate :name, to: :profile, allow_nil: true
  delegate :current_plan, to: :subscription

  def super_admin?
    ["lake.ilakela@gmail.com"].include?(email)
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

  def permission_level_name
    I18n.t("plan.level.#{permission_level}")
  end

  def current_staff_account(super_user)
    @current_staff_accounts ||= {}

    return @current_staff_accounts[super_user] if @current_staff_accounts[super_user]

    @current_staff_accounts[super_user] = super_user.owner_staff_accounts.active.find_by(user_id: self.id)
  end

  def current_staff(super_user)
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

  def trial_expired_date
    @trial_expired_date ||= created_at.advance(months: Plan::TRIAL_PLAN_THRESHOLD_MONTHS).to_date
  end

  def valid_shop_ids
    @valid_shop_ids ||= if premium_member?
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
    @google_user ||= GoogleContactsApi::User.new(access_token, refresh_token)
  end

  def owner_ability
    Ability.new(self, self)
  end

  private

  def today_reservations
    Reservation.where(shop_id: shop_ids, created_at: Time.zone.now.beginning_of_day..Time.zone.now.end_of_day)
  end

  def total_reservations
    Reservation.where(shop_id: shop_ids).active
  end
end
