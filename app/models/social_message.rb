# frozen_string_literal: true
# == Schema Information
#
# Table name: social_messages
#
#  id                 :bigint           not null, primary key
#  channel            :string
#  content_type       :string
#  message_type       :integer          default("bot")
#  raw_content        :text
#  readed_at          :datetime
#  schedule_at        :datetime
#  sent_at            :datetime
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  broadcast_id       :integer
#  customer_id        :integer
#  social_account_id  :integer
#  social_customer_id :integer
#  staff_id           :integer
#  user_id            :integer
#
# Indexes
#
#  index_social_messages_on_broadcast_id             (broadcast_id)
#  index_social_messages_on_customer_id_and_channel  (customer_id,channel)
#  index_social_messages_on_user_id_and_channel      (user_id,channel)
#  social_message_customer_index                     (social_account_id,social_customer_id)
#

class SocialMessage < ApplicationRecord
  include MalwareScannable

  belongs_to :social_account, optional: true
  belongs_to :social_customer, optional: true, touch: true
  belongs_to :user, optional: true
  belongs_to :customer, optional: true
  belongs_to :staff, optional: true
  belongs_to :broadcast, optional: true
  has_one_attached :image
  scan_attachment :image

  scope :unread, -> { where(readed_at: nil) }
  # Sometimes user's line account got some issue, message couldn't be sent successfully.
  # In that case, sent at is null and schedule_at is null as well
  scope :legal, -> { where("sent_at is NOT NULL or schedule_at is NOT NULL") }
  scope :handleable, -> { includes(social_customer: :customer).where.not(social_customers: { customer_id: nil }) }
  scope :ordered, -> { order(Arel.sql("(CASE
                                        WHEN social_messages.sent_at IS NOT NULL THEN social_messages.sent_at
                                        WHEN social_messages.schedule_at IS NOT NULL THEN social_messages.schedule_at
                                        ELSE social_messages.created_at END) DESC, social_messages.id DESC"))  }
  scope :from_customer, -> { where(message_type: [SocialMessage.message_types[:customer], SocialMessage.message_types[:customer_reply_bot]]) }

  enum message_type: {
    bot: 0,
    staff: 1,
    customer: 2,
    customer_reply_bot: 3
  }

  enum channel: {
    line: "line",
    sms: "sms",
    email: "email"
  }

  def unread?
    readed_at.nil?
  end
end
