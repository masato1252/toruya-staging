# == Schema Information
#
# Table name: custom_schedules
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  staff_id   :integer
#  start_time :datetime
#  end_time   :datetime
#  reason     :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CustomSchedule < ApplicationRecord
  attr_accessor :start_time_date_part, :start_time_time_part

  belongs_to :shop, optional: true
  belongs_to :staff, optional: true

  scope :for_shop, -> { where(staff_id: nil) }
  scope :future, -> { where("start_time > ?", Time.now.yesterday) }

  before_validation :set_start_time

  def set_start_time
    self.start_time ||= Time.zone.parse("#{start_time_date_part}-#{start_time_time_part}")
  end

  def start_time_date
    start_time.to_s(:date)
  end

  def start_time_time
    start_time.to_s(:time)
  end
end
