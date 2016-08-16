# == Schema Information
#
# Table name: reservations
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  menu_id    :integer
#  start_time :datetime
#  end_time   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Reservation < ApplicationRecord
  attr_accessor :start_time_date_part, :start_time_time_part, :end_time_time_part

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :reservation_staffs, presence: true
  validates :reservation_customers, presence: true
  validate :duplicate_staff_or_customer

  belongs_to :shop
  belongs_to :menu
  has_many :reservation_staffs
  has_many :staffs, through: :reservation_staffs
  has_many :reservation_customers
  has_many :customers, through: :reservation_customers

  before_validation :set_start_time, :set_end_time

  def set_start_time
    self.start_time ||= Time.zone.parse("#{start_time_date_part}-#{start_time_time_part}")
  end

  def set_end_time
    self.end_time ||= Time.zone.parse("#{start_time_date_part}-#{end_time_time_part}")
  end

  def start_time_date
    start_time.to_s(:date)
  end

  def start_time_time
    start_time.to_s(:time)
  end

  def end_time_time
    end_time.try(:to_s, :time)
  end

  private

  def duplicate_staff_or_customer
    scoped = Reservation.where.not(id: id).joins(:reservation_staffs, :reservation_customers).
      where("reservations.start_time <= ? AND reservations.end_time >= ?", end_time, start_time)

    if scoped.where("reservation_staffs.staff_id in (?)", staff_ids)
      .or(
        scoped.where("reservation_customers.customer_id in (?)", customer_ids)
      ).exists?
      errors.add(:base, "This is a duplicated reservation, please check your reservation time, staffs or customers")
    end
  end
end
