# frozen_string_literal: true

class TweakCustomScheduleIndex < ActiveRecord::Migration[5.0]
  def change
    remove_index :custom_schedules, column: [:shop_id, :staff_id, :start_time, :end_time], name: :custom_schedules_index
    add_index :custom_schedules, [:shop_id, :start_time, :end_time], name: :shop_custom_schedules_index
    add_index :custom_schedules, [:staff_id, :start_time, :end_time], name: :staff_custom_schedules_index
  end
end
