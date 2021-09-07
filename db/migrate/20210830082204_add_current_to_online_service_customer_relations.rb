class AddCurrentToOnlineServiceCustomerRelations < ActiveRecord::Migration[6.0]
  def up
    add_column :online_service_customer_relations, :current, :boolean
    change_column_default :online_service_customer_relations, :current, true
    remove_index :online_service_customer_relations, name: :online_service_relation_unique_index
    add_index :online_service_customer_relations, [:online_service_id, :customer_id, :current], name: :online_service_relation_unique_index, unique: true

    OnlineServiceCustomerRelation.update_all(current: true)
  end

  def down
    remove_index :online_service_customer_relations, name: :online_service_relation_unique_index
    remove_column :online_service_customer_relations, :current
    add_index :online_service_customer_relations, [:online_service_id, :customer_id], name: :online_service_relation_unique_index
  end
end
