class CreateCustomMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :custom_messages do |t|
      t.string :scenario, null: false
      t.references :service, null: false, polymorphic: true
      t.text :content, null: false

      t.timestamps
    end
  end
end
