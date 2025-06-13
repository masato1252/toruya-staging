# frozen_string_literal: true

# == Schema Information
#
# Table name: menu_equipments
#
#  id                :bigint           not null, primary key
#  required_quantity :integer          default(1), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  equipment_id      :bigint           not null
#  menu_id           :bigint           not null
#
# Indexes
#
#  index_menu_equipments_on_equipment_id              (equipment_id)
#  index_menu_equipments_on_menu_id                   (menu_id)
#  index_menu_equipments_on_menu_id_and_equipment_id  (menu_id,equipment_id) UNIQUE
#

class MenuEquipment < ApplicationRecord
  validates :required_quantity, presence: true, numericality: { greater_than: 0 }
  validates :equipment_id, uniqueness: { scope: [:menu_id] }

  belongs_to :menu
  belongs_to :equipment

  validate :equipment_belongs_to_same_shop

  private

  def equipment_belongs_to_same_shop
    return unless menu && equipment

    menu_shop_ids = menu.shops.pluck(:id)
    unless menu_shop_ids.include?(equipment.shop_id)
      errors.add(:equipment, :must_belong_to_menu_shop)
    end
  end
end