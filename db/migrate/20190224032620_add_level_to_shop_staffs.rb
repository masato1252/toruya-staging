class AddLevelToShopStaffs < ActiveRecord::Migration[5.1]
  def change
    add_column :shop_staffs, :level, :integer, default: 0, null: false
  end
end
