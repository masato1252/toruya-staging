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

class SocialRichMenu < ApplicationRecord
  belongs_to :social_account
end
