# frozen_string_literal: true

json.messages(@messages) do |message|
  json.customer message.staff_id.nil?
  json.text message.raw_content
  json.readed true
  json.created_at message.created_at
end
