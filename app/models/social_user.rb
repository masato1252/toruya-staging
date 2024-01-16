# frozen_string_literal: true
# == Schema Information
#
# Table name: social_users
#
#  id                      :bigint           not null, primary key
#  pinned                  :boolean          default(FALSE), not null
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
#  index_social_users_on_pinned_and_updated_at  (pinned,updated_at)
#  index_social_users_on_social_rich_menu_key   (social_rich_menu_key)
#  social_user_unique_index                     (user_id,social_service_user_id) UNIQUE
#

require "user_bot_social_account"

class SocialUser < ApplicationRecord
  acts_as_taggable_on :memos

  belongs_to :user, optional: true
  has_many :social_user_messages

  def client
    UserBotSocialAccount.client
  end

  def social_user_id
    social_service_user_id
  end

  def same_social_user_scope
    SocialUser.where(social_service_user_id: social_service_user_id)
  end

  def current_users
    @current_users ||= same_social_user_scope.map(&:user).compact.sort do |user1, user2|
      user1.id <=> user2.id
    end
  end

  def root_user
    @root_user ||= current_users.first
  end

  def manage_accounts
    @manage_accounts ||=
      begin
        owners = current_users.map {|user| user&.staff_accounts.where(level: "owner")&.active&.includes(:owner)&.map(&:owner) }.compact.flatten.uniq
        managers = current_users.map {|user| user&.staff_accounts.where.not(level: "owner")&.active&.includes(:owner)&.map(&:owner) }.compact.flatten.uniq
        [ owners, managers ].flatten
      end
  end
end
