class CreateFunctionAccesses < ActiveRecord::Migration[6.1]
  def change
    create_table :function_accesses do |t|
      t.string :content, null: false
      t.string :source_type
      t.string :source_id
      t.string :action_type
      t.date :access_date, null: false
      t.integer :access_count, null: false, default: 0
      t.integer :conversion_count, null: false, default: 0
      t.integer :revenue_cents, null: false, default: 0

      t.timestamps
    end

    add_index :function_accesses, [:access_date, :source_id, :content], name: 'index_function_accesses_on_content_source_and_date'
    add_index :function_accesses, [:access_date, :source_id, :source_type], name: 'index_function_accesses_on_date_and_source'
  end
end 