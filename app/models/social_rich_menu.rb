# frozen_string_literal: true

# == Schema Information
#
# Table name: social_rich_menus
#
#  id                  :bigint(8)        not null, primary key
#  social_account_id   :integer
#  social_rich_menu_id :string
#  social_name         :string
#
# Indexes
#
#  index_social_rich_menus_on_social_account_id_and_social_name  (social_account_id,social_name)
#

require "user_bot_social_account"

class SocialRichMenu < ApplicationRecord
  LINE_OFFICIAL_RICH_MENU_KEY = "line_official"

  belongs_to :social_account, required: false

  def account
    social_account || UserBotSocialAccount
  end
end
