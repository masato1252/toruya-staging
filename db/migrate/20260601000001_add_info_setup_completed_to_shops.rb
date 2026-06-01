# frozen_string_literal: true

class AddInfoSetupCompletedToShops < ActiveRecord::Migration[7.0]
  def change
    add_column :shops, :info_setup_completed, :boolean, default: true, null: false
  end
end
