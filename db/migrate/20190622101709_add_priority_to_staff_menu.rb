# frozen_string_literal: true

class AddPriorityToStaffMenu < ActiveRecord::Migration[5.2]
  def change
    add_column :staff_menus, :priority, :integer

    Menu.all.find_all do |menu|
      menu.staff_menus.each.with_index do |staff_menu, index|
        staff_menu.update_columns(priority: index)
      end
    end
  end
end
