# frozen_string_literal: true
# == Schema Information
#
# Table name: social_messages
#
#  id                 :bigint           not null, primary key
#  message_type       :integer          default("bot")
#  raw_content        :text
#  readed_at          :datetime
#  schedule_at        :datetime
#  sent_at            :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  broadcast_id       :integer
#  social_account_id  :integer          not null
#  social_customer_id :integer          not null
#  staff_id           :integer
#
# Indexes
#
#  index_social_messages_on_broadcast_id  (broadcast_id)
#  social_message_customer_index          (social_account_id,social_customer_id)
#

class SocialMessage < ApplicationRecord
  belongs_to :social_account
  belongs_to :social_customer, touch: true
  belongs_to :staff, optional: true
  belongs_to :broadcast, optional: true
  has_one_attached :image

  scope :unread, -> { where(readed_at: nil) }
  scope :handleable, -> { includes(social_customer: :customer).where.not(social_customers: { customer_id: nil }) }
  scope :ordered, -> { order("(CASE WHEN social_messages.sent_at IS NULL THEN social_messages.created_at ELSE social_messages.sent_at END) DESC, social_messages.id DESC")  }

  enum message_type: {
    bot: 0,
    staff: 1,
    customer: 2,
    customer_reply_bot: 3
  }
end
