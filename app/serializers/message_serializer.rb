class MessageSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, :created_at, :message_type

  attribute :customer_id do |message|
    message.social_customer.social_user_id
  end

  attribute :text do |message|
    message.raw_content
  end

  attribute :readed do |message|
    message.readed_at.present?
  end
end
