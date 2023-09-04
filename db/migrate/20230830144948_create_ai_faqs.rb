class CreateAiFaqs < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_faqs do |t|
      t.string :user_id, index: true
      t.text :question
      t.text :answer
      t.timestamps
    end
  end
end
