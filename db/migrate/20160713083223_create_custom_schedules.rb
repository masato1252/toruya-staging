# frozen_string_literal: true

class CreateCustomSchedules < ActiveRecord::Migration[5.0]
  def change
    create_table :custom_schedules do |t|
      t.integer :shop_id
      t.integer :staff_id
      t.datetime :start_time
      t.datetime :end_time
      t.text :reason

      t.timestamps
    end

    add_index :custom_schedules, [:shop_id, :staff_id, :start_time, :end_time], name: :custom_schedules_index
  end
end
