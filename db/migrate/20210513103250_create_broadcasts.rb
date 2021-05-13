class CreateBroadcasts < ActiveRecord::Migration[5.2]
  def change
    create_table :broadcasts do |t|
      t.references :user, null: false
      t.text :content, null: false
      t.jsonb :query, null: true
      t.datetime :schedule_at, null: true
      t.datetime :sent_at, null: true
      t.integer :state, default: 0
      t.timestamps
    end
  end
end
