# frozen_string_literal: true

# == Schema Information
#
# Table name: social_users
#
#  id                      :bigint(8)        not null, primary key
#  user_id                 :bigint(8)
#  social_service_user_id  :string           not null
#  social_user_name        :string
#  social_user_picture_url :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  social_rich_menu_key    :string
#
# Indexes
#
#  index_social_users_on_social_rich_menu_key  (social_rich_menu_key)
#  index_social_users_on_user_id               (user_id)
#  social_user_unique_index                    (user_id,social_service_user_id) UNIQUE
#

require "user_bot_social_account"

class SocialUser < ApplicationRecord
  belongs_to :user, optional: true

  def client
    UserBotSocialAccount.client
  end

  def social_user_id
    social_service_user_id
  end
end
