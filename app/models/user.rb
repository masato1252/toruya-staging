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
#  level                  :integer          default(0), not null
#

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable, :omniauthable

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

  delegate :access_token, :refresh_token, :uid, to: :access_provider, allow_nil: true
  delegate :name, to: :profile, allow_nil: true

  after_commit :create_default_ranks, on: :create

  def super_admin?
    ["lake.ilakela@gmail.com"].include?(email)
  end

  def member?
    true
  end

  def staff_account_in_shop(shop)
    shop.user.staff_accounts.find_by(user: self, active_uniqueness: true).try(:staff)
  end

  private

  def create_default_ranks
    ranks.create(name: "VIP", key: Rank::VIP_KEY)
    ranks.create(name: I18n.t("constants.rank.regular"), key: Rank::REGULAR_KEY)
  end
end
