class CreateLessons < ActiveRecord::Migration[6.0]
  def change
    create_table :lessons do |t|
      t.references :chapter
      t.string :name
      t.string :solution_type
      t.string :content_url
      t.text :note
    end
  end
end
