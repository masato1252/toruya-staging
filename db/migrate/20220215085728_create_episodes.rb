class CreateEpisodes < ActiveRecord::Migration[6.0]
  def change
    create_table :episodes do |t|
      t.references :user, null: false, index: false
      t.references :online_service, null: false
      t.string :name, null: false
      t.string :solution_type, null: false
      t.string :content_url, null: false
      t.text :note
      t.datetime :start_at
      t.datetime :end_at
      t.timestamps
    end
  end
end
