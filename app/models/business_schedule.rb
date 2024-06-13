# frozen_string_literal: true

# == Schema Information
#
# Table name: business_schedules
#
#  id              :integer          not null, primary key
#  business_state  :string
#  day_of_week     :integer
#  end_time        :datetime
#  full_time       :boolean
#  start_time      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  booking_page_id :integer
#  shop_id         :integer
#  staff_id        :integer
#
# Indexes
#
#  index_business_schedules_on_booking_page_id  (booking_page_id)
#  shop_working_time_index                      (shop_id,business_state,day_of_week,start_time,end_time)
#  staff_working_time_index                     (shop_id,staff_id,full_time,business_state,day_of_week,start_time,end_time)
#

class BusinessSchedule < ApplicationRecord
  # shop's business_schedules: Only shop_id exists
  # booking page's business_schedules: Only booking_page_id exists
  # staff's business schedules: Both shop_id, staff_id exist
  # NO only staff_id exists case

  WDAYS = [1, 2, 3, 4, 5, 6, 0].freeze
  BUSINESS_STATE = %w(opened closed).freeze
  HOLIDAY_WORKING_WDAY = 999 # used to represent the business for holiday working

  validates :shop_id, presence: true
  validates :business_state, inclusion: { in: BUSINESS_STATE }, allow_nil: true
  validates :start_time, presence: true, if: -> { business_state == "opened" }
  validates :end_time, presence: true, if: -> { business_state == "opened" }

  belongs_to :shop, optional: true
  belongs_to :staff, optional: true
  belongs_to :booking_page, optional: true

  scope :for_shop, -> { where(staff_id: nil, booking_page_id: nil) }
  scope :for_staff, -> { where.not(staff_id: nil) }
  scope :opened, -> { where(business_state: "opened") }
  scope :full_time, -> { where(full_time: true) }
  scope :part_time, -> { where(full_time: nil) }
  scope :holiday_working, -> { where(day_of_week: HOLIDAY_WORKING_WDAY) }

  def start_time_on(date)
    start_time.change(year: date.year, month: date.month, day: date.day)
  end

  def end_time_on(date)
    end_time.change(year: date.year, month: date.month, day: date.day)
  end
end
