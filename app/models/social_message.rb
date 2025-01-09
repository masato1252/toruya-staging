# frozen_string_literal: true
# == Schema Information
#
# Table name: social_messages
#
#  id                 :bigint           not null, primary key
#  content_type       :string
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

  def unread?
    readed_at.nil?
  end
end