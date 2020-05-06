class MessageSerializer
  include FastJsonapi::ObjectSerializer
  attribute :id, :created_at

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
