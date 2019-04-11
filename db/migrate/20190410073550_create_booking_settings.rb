class CreateBookingSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :booking_pages do |t|
      t.references :user, null: false
      t.references :shop, null: false
      t.string :name, null: false
      t.string :title
      t.text :greeting
      t.text :note
      t.integer :interval
      t.timestamps
    end

    create_table :booking_options do |t|
      t.references :user, null: false
      t.string :name, null: false
      t.string :display_name
      t.integer :minutes
      t.integer :interval
      t.decimal :amount_cents
      t.string :amount_currency
      t.boolean :tax_include
      t.datetime :start_at
      t.datetime :end_at
      t.text :memo

      t.timestamps
    end

    create_table :booking_option_menus do |t|
      t.references :booking_option, null: false
      t.references :menu, null: false
    end

    create_table :booking_page_options do |t|
      t.references :booking_page, null: false
      t.references :booking_option, null: false
    end
  end
end
