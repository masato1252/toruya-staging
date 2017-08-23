class AddWorkingPermissionToShopStaffs < ActiveRecord::Migration[5.0]
  def change
    add_column :shop_staffs, :staff_regular_working_day_permission, :boolean, null: false, default: false
    add_column :shop_staffs, :staff_temporary_working_day_permission, :boolean, null: false, default: false
  end
end
