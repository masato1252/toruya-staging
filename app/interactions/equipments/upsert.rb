# frozen_string_literal: true

module Equipments
  class Upsert < ActiveInteraction::Base
    object :shop
    object :equipment, default: nil
    string :name
    integer :quantity, default: 1
    array :equipment_menus, default: nil, strip: false do
      hash do
        integer :menu_id
        boolean :checked, default: false
        integer :required_quantity, default: 1
      end
    end

    def execute
      eq = equipment || shop.equipments.build
      eq.assign_attributes(name: name, quantity: quantity)

      Equipment.transaction do
        eq.save!
        if equipment_menus
          eq.menu_equipments.destroy_all
          equipment_menus.each do |menu_data|
            next unless menu_data[:checked] || menu_data['checked'] == true || menu_data['checked'] == 'true'
            menu_id = menu_data[:menu_id] || menu_data['menu_id']
            required_quantity = menu_data[:required_quantity] || menu_data['required_quantity'] || 1
            eq.menu_equipments.create!(menu_id: menu_id, required_quantity: required_quantity)
          end
        end
      end
      eq
    rescue ActiveRecord::RecordInvalid => e
      errors.add(:base, e.message)
    end
  end
end