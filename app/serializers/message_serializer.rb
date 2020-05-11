class MessageSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, :created_at

  attribute :customer_id do |message|
    message.social_customer.social_user_id
  end

  attribute :text do |message|
    message.raw_content
  end

  attribute :customer do |message|
    message.staff_id.nil?
  end

  attribute :readed do |message|
    message.readed_at.present?
  end
end
