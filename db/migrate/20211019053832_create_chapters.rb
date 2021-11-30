class CreateChapters < ActiveRecord::Migration[6.0]
  def change
    create_table :chapters do |t|
      t.references :online_service
      t.string :name
      t.timestamps
    end
  end
end
