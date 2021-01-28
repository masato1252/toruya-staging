class CreateOnlineServices < ActiveRecord::Migration[5.2]
  def change
    create_table :online_services do |t|
      t.references :user
      t.string :name, null: false
      t.string :goal_type, null: false
      t.string :solution_type, null: false
      t.datetime :end_at
      t.integer :end_on_days
      t.integer :upsell_sale_page_id
      t.json :content
      t.references :company, polymorphic: true, null: false, index: false
      t.string :slug, index: true
      t.timestamps
    end
  end
end
