class AddContentTypeToSocialMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :social_messages, :content_type, :string
  end
end
