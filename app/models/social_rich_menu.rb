# frozen_string_literal: true

# == Schema Information
#
# Table name: social_rich_menus
#
#  id                  :bigint           not null, primary key
#  body                :jsonb
#  current             :boolean
#  default             :boolean
#  end_at              :datetime
#  social_name         :string
#  start_at            :datetime
#  social_account_id   :integer
#  social_rich_menu_id :string
#
# Indexes
#
#  current_rich_menu                                             (social_account_id,current) UNIQUE
#  default_rich_menu                                             (social_account_id,default) UNIQUE
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
