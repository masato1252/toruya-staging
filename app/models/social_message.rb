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
#
# Indexes
#
#  social_message_customer_index  (social_account_id,social_customer_id)
#

class SocialMessage < ApplicationRecord
  belongs_to :social_account
  belongs_to :social_customer
  belongs_to :staff, optional: true

  scope :unread, -> { where(readed_at: nil) }
end
