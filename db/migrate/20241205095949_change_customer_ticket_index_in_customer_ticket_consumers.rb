class ChangeCustomerTicketIndexInCustomerTicketConsumers < ActiveRecord::Migration[7.0]
  def change
    remove_index :customer_ticket_consumers, column: [:consumer_id, :consumer_type]
    add_index :customer_ticket_consumers, [:customer_ticket_id, :consumer_id, :consumer_type], unique: true, name: 'index_customer_ticket'
  end
end
