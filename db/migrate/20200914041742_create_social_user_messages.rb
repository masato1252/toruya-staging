# frozen_string_literal: true

class CreateSocialUserMessages < ActiveRecord::Migration[5.2]
  def change
    create_table :social_user_messages do |t|
      t.integer :social_user_id, null: false
      t.integer :admin_user_id
      t.integer :message_type
      t.datetime :readed_at
      t.text :raw_content

      t.timestamps
    end

    add_index :social_user_messages, [:social_user_id], name: :social_user_message_index
  end
end
