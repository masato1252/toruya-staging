class CustomerSerializer
  include FastJsonapi::ObjectSerializer
  attribute :created_at

  attribute :id do |customer|
    customer.social_user_id
  end

  attribute :name do |customer|
    customer.social_user_name
  end

  attribute :new_messages_count do |customer|
    customer.social_messages.unread.count
  end

  attribute :last_message_at do |customer|
    customer.social_messages.last&.created_at
  end
end
