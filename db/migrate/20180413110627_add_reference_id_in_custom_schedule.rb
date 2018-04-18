class AddReferenceIdInCustomSchedule < ActiveRecord::Migration[5.1]
  def change
    add_column :custom_schedules, :reference_id, :string
    add_index :custom_schedules, :reference_id
  end
end
