# == Schema Information
#
# Table name: business_schedules
#
#  id             :integer          not null, primary key
#  shop_id        :integer
#  staff_id       :integer
#  full_time      :boolean
#  business_state :string
#  day_of_week    :integer
#  start_time     :datetime
#  end_time       :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class BusinessSchedule < ApplicationRecord
  WDAYS = [1, 2, 3, 4, 5, 6, 0].freeze
  BUSINESS_STATE = %w(opened closed).freeze

  validates :shop_id, presence: true
  validates :day_of_week, uniqueness: { scope: [:shop_id, :staff_id, :day_of_week] }
  validates :day_of_week, inclusion: { in: 0..6 }, if: -> { day_of_week.present? }
  validates :business_state, inclusion: { in: BUSINESS_STATE }, allow_nil: true
  validates :start_time, presence: true, if: -> { business_state == "opened" }
  validates :end_time, presence: true, if: -> { business_state == "opened" }

  belongs_to :shop, optional: true
  belongs_to :staff, optional: true

  scope :for_shop, -> { where(staff_id: nil) }
  scope :for_staff, -> { where.not(staff_id: nil) }
  scope :opened, -> { where(business_state: "opened") }
  scope :full_time, -> { where(full_time: true) }
  scope :part_time, -> { where(full_time: nil) }
end
