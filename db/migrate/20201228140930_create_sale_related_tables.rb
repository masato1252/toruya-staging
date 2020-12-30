require "seeders/sale_template"

class CreateSaleRelatedTables < ActiveRecord::Migration[5.2]
  def change
    create_table :sale_templates do |t|
      t.json :edit_body
      t.json :view_body
      t.timestamps
    end

    create_table :sale_pages do |t|
      t.references :user
      t.references :staff
      t.references :product, polymorphic: true, null: false
      t.references :sale_template
      t.json :sale_template_variables
      t.json :content
      t.json :flow

      t.timestamps
    end

    Seeders::SaleTemplate.seed!
  end
end
