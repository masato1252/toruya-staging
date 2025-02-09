# frozen_string_literal: true
# == Schema Information
#
# Table name: social_users
#
#  id                      :bigint           not null, primary key
#  consultant_at           :datetime
#  locale                  :string           default("ja")
#  pinned                  :boolean          default(FALSE), not null
#  release_version         :string
#  social_rich_menu_key    :string
#  social_user_name        :string
#  social_user_picture_url :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  social_service_user_id  :string           not null
#  user_id                 :bigint
#
# Indexes
#
#  index_social_users_on_consultant_at          (consultant_at)
#  index_social_users_on_pinned_and_updated_at  (pinned,updated_at)
#  index_social_users_on_social_rich_menu_key   (social_rich_menu_key)
#  social_user_unique_index                     (user_id,social_service_user_id) UNIQUE
#

require "user_bot_social_account"
require "tw_user_bot_social_account"

# locale means the locale where user sign up their account(sign up from tw or ja)

class SocialUser < ApplicationRecord
  acts_as_taggable_on :memos
  ADMIN_IDS = [
    "U685b963671382e6c591f71f2346197f4", # Dev
    "U6de618891f1113d0d7c07ce3dd209540",
    "Ud5a6c48f7716e81f8086d1a9467fea42",
    "Ua13ed6ae1390795b84f78eb30efb410e",
    "Ube9f9b68d4b028c8407c50cc9e951b5e",
    "U5f5528373cf1e4f849ad7253ed38a918"
  ].freeze

  belongs_to :user, optional: true
  has_many :social_user_messages

  def super_admin?
    ADMIN_IDS.include?(social_service_user_id)
  end

  def single_owner?
    manage_accounts.size == 1
  end

  def client
    locale == 'tw' ? TwUserBotSocialAccount.client : UserBotSocialAccount.client
  end

  def social_user_id
    social_service_user_id
  end

  def same_social_user_scope
    SocialUser.where(social_service_user_id: social_service_user_id)
  end

  def current_users
    @current_users ||= same_social_user_scope.includes(user: :staff_accounts).map(&:user).compact.sort do |user1, user2|
      user1.id <=> user2.id
    end
  end

  def root_user
    @root_user ||= current_users.first
  end

  def japanese?
    locale == "ja" || user.locale == :ja
  end

  def manage_accounts
    @manage_accounts ||=
      begin
        owners = current_users.map {|user| user.staff_accounts.where(level: "owner").active.includes(owner: :profile).map(&:owner) }.flatten.uniq
        managers = current_users.map {|user| user.staff_accounts.where.not(level: "owner").active.includes(owner: :profile).map(&:owner) }.flatten.uniq

        [ owners, managers ].flatten.uniq
      end
  end

  def shops
    manage_accounts.map(&:shops).flatten
  end

  def staffs
    StaffAccount.where(user: current_users).active.includes(:staff).map(&:staff)
  end

  def language
    I18n.available_locales.include?(locale&.to_sym) ? locale.to_sym : I18n.default_locale
  end
end
