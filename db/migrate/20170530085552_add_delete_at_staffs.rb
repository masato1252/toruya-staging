class AddDeleteAtStaffs < ActiveRecord::Migration[5.0]
  def change
    add_column :staffs, :deleted_at, :datetime
  end
end
