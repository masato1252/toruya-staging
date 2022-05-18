class AddFlexAttributesToCustomMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :custom_messages, :flex_template, :string, null: true
    add_column :custom_messages, :content_type, :string
    change_column_default :custom_messages, :content_type, "text"

    CustomMessage.unscoped.in_batches do |relation|
      relation.update_all content_type: "text"
      sleep(0.01)
    end
  end
end
