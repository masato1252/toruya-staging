# == Schema Information
#
# Table name: social_messages
#
#  id                 :bigint(8)        not null, primary key
#  social_account_id  :integer          not null
#  social_customer_id :integer          not null
#  staff_id           :integer
#  raw_content        :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  readed_at          :datetime
#  message_type       :integer          default("bot")
#
# Indexes
#
#  social_message_customer_index  (social_account_id,social_customer_id)
#

class SocialMessage < ApplicationRecord
  belongs_to :social_account
  belongs_to :social_customer, touch: true
  belongs_to :staff, optional: true

  scope :unread, -> { where(readed_at: nil) }

  enum message_type: {
    bot: 0,
    staff: 1,
    customer: 2,
    customer_reply_bot: 3
  }
end
