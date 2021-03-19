# frozen_string_literal: true

class AddOpenToCustomSchedules < ActiveRecord::Migration[5.0]
  def change
    add_column :custom_schedules, :open, :boolean, default: false, null: false
    add_index :custom_schedules, [:staff_id, :open]
  end
end
