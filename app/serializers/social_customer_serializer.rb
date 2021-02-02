# frozen_string_literal: true

class SocialCustomerSerializer
  include JSONAPI::Serializer
  attribute :created_at, :conversation_state

  attribute :id do |customer|
    customer.social_user_id
  end

  attribute :shop_customer do |social_customer|
    social_customer.customer ? CustomerSerializer.new(social_customer.customer).attributes_hash : nil
  end

  attribute :channel_id do |customer|
    customer.social_account.channel_id
  end

  attribute :name do |customer|
    customer.social_user_name
  end

  attribute :unread_message_count do |customer|
    customer.social_messages.unread.count
  end

  attribute :picture_url do |customer|
    customer.social_user_picture_url.presence || "https://via.placeholder.com/60"
  end
end
