class AddTagsToCustomers < ActiveRecord::Migration[7.0]
  def change
    add_column :customers, :tags, :string, array: true
    change_column_default :customers, :tags, []
  end
end
