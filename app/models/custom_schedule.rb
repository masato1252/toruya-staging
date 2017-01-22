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
#  open       :boolean          default(FALSE), not null
#

class CustomSchedule < ApplicationRecord
  attr_accessor :start_time_date_part, :start_time_time_part, :end_time_time_part

  belongs_to :shop, optional: true
  belongs_to :staff, optional: true

  scope :for_shop, -> { where(staff_id: nil) }
  scope :future, -> { where("start_time > ?", Time.now.at_beginning_of_day) }
  scope :opened, -> { where(open: true) }
  scope :closed, -> { where(open: false) }

  before_validation :set_start_time, :set_end_time

  def set_start_time
    if start_time_date_part && start_time_time_part
      self.start_time = Time.zone.parse("#{start_time_date_part}-#{start_time_time_part}")
    end
  end

  def set_end_time
    if start_time_date_part && end_time_time_part
      self.end_time = Time.zone.parse("#{start_time_date_part}-#{end_time_time_part}")
    end
  end

  def start_time_date
    start_time.to_s(:date)
  end

  def start_time_time
    start_time.to_s(:time)
  end
end
