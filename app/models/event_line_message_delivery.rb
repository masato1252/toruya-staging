# frozen_string_literal: true

# == Schema Information
#
# Table name: event_line_message_deliveries
#
#  id                            :bigint           not null, primary key
#  error_message                 :text
#  sent_at                       :datetime
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  event_line_message_setting_id :bigint           not null
#  event_line_user_id            :bigint           not null
#
class EventLineMessageDelivery < ApplicationRecord
  belongs_to :event_line_message_setting
  belongs_to :event_line_user

  validates :event_line_user_id, uniqueness: { scope: :event_line_message_setting_id }
end
