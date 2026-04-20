# frozen_string_literal: true

# == Schema Information
#
# Table name: event_content_usages
#
#  id                 :bigint           not null, primary key
#  started_at         :datetime         not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  event_content_id   :bigint           not null
#  event_line_user_id :bigint
#  social_customer_id :bigint
#
# Indexes
#
#  idx_evt_content_usages_unique                     (event_content_id,social_customer_id) UNIQUE
#  index_event_content_usages_on_event_content_id    (event_content_id)
#  index_event_content_usages_on_event_line_user_id  (event_line_user_id)
#  index_event_content_usages_on_social_customer_id  (social_customer_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#  fk_rails_...  (event_line_user_id => event_line_users.id)
#  fk_rails_...  (social_customer_id => social_customers.id)
#
class EventContentUsage < ApplicationRecord
  belongs_to :event_content
  belongs_to :event_line_user

  validates :started_at, presence: true
  validates :event_line_user_id, uniqueness: { scope: :event_content_id }
end
