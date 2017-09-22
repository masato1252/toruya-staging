class CreateQueryFilters < ActiveRecord::Migration[5.0]
  def change
    create_table :query_filters do |t|
      t.belongs_to :user, null: false
      t.string :name, null: false
      t.string :type, null: false
      t.jsonb :query

      t.timestamps
    end
  end
end
