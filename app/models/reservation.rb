# == Schema Information
#
# Table name: reservations
#
#  id         :integer          not null, primary key
#  shop_id    :integer          not null
#  menu_id    :integer          not null
#  start_time :datetime         not null
#  end_time   :datetime         not null
#  aasm_state :string           not null
#  memo       :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Reservation < ApplicationRecord
  include AASM
  attr_accessor :start_time_date_part, :start_time_time_part, :end_time_time_part

  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :reservation_staffs, presence: true
  validate :end_time_larger_than_start_time
  validate :duplicate_staff_or_customer
  validate :enough_staffs_for_customers

  belongs_to :shop
  belongs_to :menu
  has_many :reservation_staffs, dependent: :destroy
  has_many :staffs, through: :reservation_staffs
  has_many :reservation_customers, dependent: :destroy
  has_many :customers, through: :reservation_customers

  before_validation :set_start_time, :set_end_time

  scope :visible, -> { where("aasm_state != ?", "canceled") }
  scope :in_date, ->(date) { where("start_time >= ? AND start_time <= ?", date.beginning_of_day, date.end_of_day) }

  aasm do
    state :pending, initial: true
    state :reserved, :noshow, :checked_in, :checked_out, :canceled

    event :pend do
      transitions from: [:reserved, :noshow, :checked_out], to: :pending
    end

    event :accept do
      transitions from: :pending, to: :reserved
    end

    event :check_in do
      transitions from: [:reserved, :noshow], to: :checked_in
    end

    event :check_out do
      transitions from: :checked_in, to: :checked_out
    end

    # event :cancel do
    #   transitions from: [:pending, :reserved, :noshow, :checked_in], to: :canceled
    # end
  end

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

  def end_time_time
    end_time.try(:to_s, :time)
  end

  private

  def end_time_larger_than_start_time
    if start_time && end_time
      end_time > start_time
    end
  end

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

  def enough_staffs_for_customers
    min_staffs_number = menu.min_staffs_number
    return unless min_staffs_number

    if staff_ids.size < min_staffs_number
      errors.add(:base, "Not enough staffs for menu")
    elsif min_staffs_number == 1 && StaffMenu.where(staff_id: staff_ids, menu_id: menu_id).sum(:max_customers) < customer_ids.size
      errors.add(:base, "Not enough staffs for customers")
    elsif min_staffs_number > 1 && menu.max_seat_number < customer_ids.size
      errors.add(:base, "Not enough seat for customers")
    end
  end
end
