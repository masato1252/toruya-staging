class AddDeletedAtToMenus < ActiveRecord::Migration[5.1]
  def change
    add_column :menus, :deleted_at, :datetime
  end
end
