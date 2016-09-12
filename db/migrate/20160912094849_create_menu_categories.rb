class CreateMenuCategories < ActiveRecord::Migration[5.0]
  def change
    create_table :menu_categories do |t|
      t.integer :menu_id
      t.integer :category_id

      t.timestamps
    end

    add_index :menu_categories, [:menu_id, :category_id]
  end
end
