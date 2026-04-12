# frozen_string_literal: true

# == Schema Information
#
# Table name: event_upsell_consultations
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("waitlist"), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  customer_id        :integer
#  event_content_id   :bigint           not null
#  event_line_user_id :bigint
#  social_customer_id :bigint           not null
#
# Indexes
#
#  idx_evt_upsell_consults_unique                          (event_content_id,social_customer_id) UNIQUE
#  index_event_upsell_consultations_on_event_content_id    (event_content_id)
#  index_event_upsell_consultations_on_event_line_user_id  (event_line_user_id)
#  index_event_upsell_consultations_on_social_customer_id  (social_customer_id)
#  index_event_upsell_consultations_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (event_content_id => event_contents.id)
#  fk_rails_...  (event_line_user_id => event_line_users.id)
#  fk_rails_...  (social_customer_id => social_customers.id)
#
class EventUpsellConsultation < ApplicationRecord
  belongs_to :event_content
  belongs_to :event_line_user

  enum status: { waitlist: 0, confirmed: 1 }, _suffix: true

  validates :event_line_user_id, uniqueness: { scope: :event_content_id }
end
