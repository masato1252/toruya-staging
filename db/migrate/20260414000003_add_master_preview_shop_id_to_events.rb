class AddMasterPreviewShopIdToEvents < ActiveRecord::Migration[7.0]
  def change
    add_reference :events, :master_preview_shop, foreign_key: { to_table: :shops }, null: true
  end
end
