# == Schema Information
#
# Table name: user_settings
#
#  id      :bigint           not null, primary key
#  content :json
#  user_id :bigint
#
# Indexes
#
#  index_user_settings_on_user_id  (user_id)
#
class UserSetting < ApplicationRecord
  typed_store :content do |s|
    s.string :line_keyword_booking_page_ids, array: true, default: [], null: false
    s.string :line_keyword_booking_option_ids, array: true, default: [], null: false
  end
end
