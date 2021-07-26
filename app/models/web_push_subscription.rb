# frozen_string_literal: true

# == Schema Information
#
# Table name: web_push_subscriptions
#
#  id         :bigint           not null, primary key
#  auth_key   :string
#  endpoint   :string
#  p256dh_key :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint
#
# Indexes
#
#  index_web_push_subscriptions_on_user_id  (user_id)
#

class WebPushSubscription < ApplicationRecord
  belongs_to :user
end
