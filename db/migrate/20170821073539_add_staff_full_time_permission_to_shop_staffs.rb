class AddStaffFullTimePermissionToShopStaffs < ActiveRecord::Migration[5.0]
  def change
    add_column :shop_staffs, :staff_full_time_permission, :boolean, null: false, default: false
  end
end
