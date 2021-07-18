# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id             :bigint           not null, primary key
#  charged        :boolean          default(FALSE)
#  content        :text
#  phone_number   :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  customer_id    :integer
#  reservation_id :integer
#  user_id        :integer
#
# Indexes
#
#  index_notifications_on_user_id_and_charged  (user_id,charged)
#

# For record SMS sent
# @user_id presents: Send the notification for the user
# @user_id is null: Send the notification for Toruya
class Notification < ApplicationRecord
  belongs_to :user, optional: true
end
