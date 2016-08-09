# == Schema Information
#
# Table name: reservation_settings
#
#  id               :integer          not null, primary key
#  menu_id          :integer
#  name             :string
#  short_name       :string
#  reservation_type :string
#  day_type         :string
#  time_type        :string
#  day              :integer
#  day_of_week      :integer
#  nth_of_week      :integer
#  start_time       :datetime
#  end_time         :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class ReservationSetting < ApplicationRecord
  TYPES = %w(flex block).freeze
  DAY_TYPES = %w(business_days weekly number_of_day_monthly day_of_week_monthly).freeze
  TIME_TYPES = %w(business_days custom) # probably don't need, has start_time and end_time means custom, otherwise it is bussiness_days.
  DAYS = 1..31
  DAYS_OF_WEEK = 1..7

  belongs_to :menu
end
