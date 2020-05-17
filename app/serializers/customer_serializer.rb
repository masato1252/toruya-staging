class CustomerSerializer
  include FastJsonapi::ObjectSerializer
  attribute :created_at, :conversation_state

  attribute :id do |customer|
    customer.social_user_id
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

  attribute :last_message_at do |customer|
    customer.social_messages.last&.created_at
  end
end
