class CreateTickets < ActiveRecord::Migration[7.0]
  def change
    # what kind of ticket user own
    create_table :tickets do |t|
      t.references :user
      t.string :ticket_type, default: "single"
      t.timestamps
    end

    # the real ticket what customer own
    create_table :customer_tickets do |t|
      t.references :ticket, null: false, index: true
      t.references :customer, null: false, index: true # booking_option
      t.integer :total_quota, null: false # quota might be money amount, or using times
      t.integer :consumed_quota, default: 0, null: false
      t.string :state, null: false
      t.string :code, null: false, index: true
      t.datetime :expire_at

      t.timestamps
    end

    # What consume the ticket quota
    create_table :customer_ticket_consumers do |t|
      t.references :customer_ticket, null: false
      # one consumer only be used in any ticket once
      t.references :consumer, polymorphic: true, null: false
      t.integer :ticket_quota_consumed, null: true

      t.timestamps
    end
    add_index :customer_ticket_consumers, [:consumer_id, :consumer_type], unique: true, name: "consumer_ticket_index"

    # Ticket could be used in what product, in the beginning is only for booking option
    create_table :ticket_products do |t|
      t.references :ticket, null: false, index: true
      t.references :product, null: false, polymorphic: true, index: true # booking_option
      t.timestamps
    end

    add_column :booking_options, :ticket_quota, :integer, default: 1, null: false
    add_column :booking_options, :ticket_expire_month, :integer, default: 1, null: false
    # de-normalize
    add_column :reservation_customers, :nth_quota, :integer
    add_column :reservation_customers, :customer_ticket_id, :integer
  end
end
