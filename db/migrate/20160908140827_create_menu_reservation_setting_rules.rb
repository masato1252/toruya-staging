# frozen_string_literal: true

class CreateMenuReservationSettingRules < ActiveRecord::Migration[5.0]
  def change
    create_table :menu_reservation_setting_rules do |t|
      t.integer :menu_id
      t.string :reservation_type
      t.date :start_date
      t.date :end_date
      t.integer :repeats

      t.timestamps
    end

    add_index :menu_reservation_setting_rules, [:menu_id, :reservation_type, :start_date, :end_date], name: :menu_reservation_setting_rules_index
  end
end
