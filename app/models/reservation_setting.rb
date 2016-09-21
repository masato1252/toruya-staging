# == Schema Information
#
# Table name: reservation_settings
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  name         :string
#  short_name   :string
#  day_type     :string
#  day          :integer
#  nth_of_week  :integer
#  days_of_week :string           default([]), is an Array
#  start_time   :datetime
#  end_time     :datetime
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class ReservationSetting < ApplicationRecord
  default_value_for :day_type, "business_days"

  DAY_TYPES = %w(business_days weekly monthly).freeze
  DAYS = 1..31
  WDAY_OF_WEEK = 0..6 # 0 is Sunday

  validates :name, presence: true
  validates :day_type, presence: true, inclusion: { in: DAY_TYPES }
  validates :day, inclusion: { in: DAYS }, allow_blank: true

  belongs_to :user

  def number_of_day_monthly?
    day.present?
  end
end
