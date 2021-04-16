# == Schema Information
#
# Table name: custom_messages
#
#  id           :bigint(8)        not null, primary key
#  scenario     :string           not null
#  service_type :string           not null
#  service_id   :bigint(8)        not null
#  content      :text             not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_custom_messages_on_service_type_and_service_id  (service_type,service_id)
#

class CustomMessage < ApplicationRecord
  ONLINE_SERVICE_PURCHASED = "online_service_purchased"

  belongs_to :service, polymorphic: true # OnlineService
end
