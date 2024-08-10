class CreateProductRequirements < ActiveRecord::Migration[7.0]
  def change
    create_table :product_requirements do |t|
      t.references :requirer, polymorphic: true, null: false
      t.references :requirement, polymorphic: true, null: false
      t.integer :sale_page_id, index: true

      t.timestamps
    end
  end
end
