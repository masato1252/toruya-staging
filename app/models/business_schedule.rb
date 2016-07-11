# == Schema Information
#
# Table name: business_schedules
#
#  id             :integer          not null, primary key
#  shop_id        :integer
#  staff_id       :integer
#  business_state :string
#  start_time     :time
#  end_time       :time
#  days_of_week   :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BusinessSchedule < ApplicationRecord
  WDAYS = [1, 2, 3, 4, 5, 6, 0].freeze
  BUSINESS_STATE = %w(opened closed).freeze

  validates :shop_id, presence: true
  validates :days_of_week, uniqueness: { scope: [:shop_id, :days_of_week] }, if: -> { !staff_id }
  validates :days_of_week, inclusion: { in: 0..6 }, if: -> { days_of_week.present? }
  validates :business_state, inclusion: { in: BUSINESS_STATE }

  scope :for_shop, -> { where(staff_id: nil) }
end
