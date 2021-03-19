# frozen_string_literal: true

class AddDeletedAtToShops < ActiveRecord::Migration[5.1]
  def change
    add_column :shops, :deleted_at, :datetime
  end
end
