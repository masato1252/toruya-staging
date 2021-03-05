# frozen_string_literal: true

class SocialUserSerializer
  include JSONAPI::Serializer
  attribute :created_at

  attribute :id do |social_user|
    social_user.social_service_user_id
  end

  attribute :shop_customer do |social_user|
    social_user.user&.profile ? ProfileSerializer.new(social_user.user.profile).attributes_hash : nil
  end

  attribute :channel_id do
    AdminChannel::CHANNEL_NAME
  end

  attribute :name do |social_user|
    social_user.social_user_name
  end

  attribute :unread_message_count do |social_user|
    social_user.social_user_messages.unread.count
  end

  attribute :picture_url do |social_user|
    social_user.social_user_picture_url.presence || "https://via.placeholder.com/60"
  end
end
