# == Schema Information
#
# Table name: notifications
#
#  id             :bigint(8)        not null, primary key
#  user_id        :integer          not null
#  phone_number   :string
#  content        :text
#  customer_id    :integer
#  reservation_id :integer
#  charged        :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_notifications_on_user_id_and_charged  (user_id,charged)
#

# phone_number presents: SMS Notification
# phone_number empty: Line Notification
class Notification < ApplicationRecord
  belongs_to :user
end
