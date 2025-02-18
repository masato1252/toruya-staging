# frozen_string_literal: true

FactoryBot.define do
  factory :user_setting do
    user_id { create(:user).id }
    customer_notification_channel { 'email' }
  end
end