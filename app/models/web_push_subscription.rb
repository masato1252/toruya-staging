# == Schema Information
#
# Table name: web_push_subscriptions
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)
#  endpoint   :string
#  p256dh_key :string
#  auth_key   :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_web_push_subscriptions_on_user_id  (user_id)
#

class WebPushSubscription < ApplicationRecord
  belongs_to :user
end
