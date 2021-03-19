class CreateOnlineServiceCustomerRelations < ActiveRecord::Migration[5.2]
  def change
    create_table :online_service_customer_relations do |t|
      t.integer :online_service_id, null: false
      t.integer :sale_page_id, null: false
      t.integer :customer_id, null: false
      t.integer :payment_state, null: false, default: 0
      t.integer :permission_state, null: false, default: 0
      t.datetime :paid_at
      t.datetime :expire_at
      t.json :product_details
      t.timestamps
    end

    add_index :online_service_customer_relations, [:online_service_id, :customer_id], unique: true, name: :online_service_relation_unique_index
    add_index :online_service_customer_relations, [:online_service_id, :customer_id, :permission_state], name: :online_service_relation_index
  end
end
