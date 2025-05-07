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
  belongs_to :user
  typed_store :content do |s|
    s.string :line_keyword_booking_page_ids, array: true, default: [], null: false
    s.string :line_keyword_booking_option_ids, array: true, default: [], null: false
    s.boolean :line_contact_customer_name_required, default: false, null: false
    s.string :customer_tags, array: true, default: [], null: false
    s.boolean :toruya_message_reply, default: false, null: false
    s.boolean :booking_options_menu_concept, default: true, null: false
    # default is email
    # paid user can choose email, line
    # line verified user change to line
    s.string :customer_notification_channel, default: "email", null: false # email, line
  end
end
