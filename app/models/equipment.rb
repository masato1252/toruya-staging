# frozen_string_literal: true

# == Schema Information
#
# Table name: equipments
#
#  id         :bigint           not null, primary key
#  deleted_at :datetime
#  name       :string           not null
#  quantity   :integer          default(1), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  shop_id    :bigint           not null
#
# Indexes
#
#  index_equipments_on_name                    (name)
#  index_equipments_on_shop_id                 (shop_id)
#  index_equipments_on_shop_id_and_deleted_at  (shop_id,deleted_at)
#

class Equipment < ApplicationRecord
  self.table_name = 'equipments'

  validates :name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }

  belongs_to :shop
  has_many :menu_equipments, dependent: :destroy
  has_many :menus, through: :menu_equipments

  scope :active, -> { where(deleted_at: nil) }

  def available_quantity_for_time_range(start_time, end_time, reservation_id = nil)
    # Calculate how many units are currently reserved during this time
    used_quantity = calculate_used_quantity(start_time, end_time, reservation_id)
    quantity - used_quantity
  end

  def sufficient_for_reservation?(required_quantity, start_time, end_time, reservation_id = nil)
    available_quantity_for_time_range(start_time, end_time, reservation_id) >= required_quantity
  end

  private

  def calculate_used_quantity(start_time, end_time, reservation_id = nil)
    # Find all reservations that overlap with the given time range
    # and use this equipment through their menus
    reservations = Reservation.joins(menus: :menu_equipments)
                            .where(menu_equipments: { equipment_id: id })
                            .where("reservations.start_time < ? AND reservations.end_time > ?", end_time, start_time)
                            .where.not(aasm_state: "canceled")
                            .where(deleted_at: nil)

    # Exclude the current reservation if updating
    reservations = reservations.where.not(id: reservation_id) if reservation_id

    # Sum up the required quantities
    reservations.joins(menus: :menu_equipments)
                .where(menu_equipments: { equipment_id: id })
                .sum("menu_equipments.required_quantity")
  end
end
