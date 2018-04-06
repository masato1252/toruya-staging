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
#  level                  :integer          default("free"), not null
#

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :omniauthable

  enum level: {
    free: 0,
    basic: 1,
    premium: 2
  }, _suffix: true

  has_one :access_provider, dependent: :destroy
  has_one :profile, dependent: :destroy
  has_many :shops
  has_many :menus
  has_many :staffs
  has_many :customers
  has_many :reservation_settings
  has_many :categories
  has_many :ranks
  has_many :contact_groups
  has_many :staff_accounts, foreign_key: :user_id
  has_many :owner_staff_accounts, class_name: "StaffAccount", foreign_key: :owner_id
  has_many :customer_query_filters
  has_many :reservation_query_filters
  has_many :filtered_outcomes

  delegate :access_token, :refresh_token, :uid, to: :access_provider, allow_nil: true
  delegate :name, to: :profile, allow_nil: true

  after_commit :create_default_ranks, on: :create

  def super_admin?
    ["lake.ilakela@gmail.com"].include?(email)
  end

  # shop owner or staffs
  def member?
    true
  end

  def current_staff_account(super_user)
    @current_staff_accounts ||= {}

    return @current_staff_accounts[super_user] if @current_staff_accounts[super_user]

    @current_staff_accounts[super_user] = super_user.owner_staff_accounts.find_by(user_id: self.id)
  end

  def current_staff(super_user)
    @current_staffs ||= {}

    return @current_staffs[super_user] if @current_staffs[super_user]

    @current_staffs[super_user] = current_staff_account(super_user).try(:staff)
  end

  private

  def create_default_ranks
    ranks.create(name: "VIP", key: Rank::VIP_KEY)
    ranks.create(name: I18n.t("constants.rank.regular"), key: Rank::REGULAR_KEY)
  end
end
