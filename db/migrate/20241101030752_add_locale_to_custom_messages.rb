class AddLocaleToCustomMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_messages, :locale, :string, default: "ja"
    CustomMessage.update_all(locale: "ja")
  end
end
