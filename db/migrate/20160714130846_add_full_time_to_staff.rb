class AddFullTimeToStaff < ActiveRecord::Migration[5.0]
  def change
    add_column :staffs, :full_time, :boolean
    add_index :staffs, [:shop_id, :full_time]
  end
end
