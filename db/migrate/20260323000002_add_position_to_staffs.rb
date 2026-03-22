# frozen_string_literal: true

class AddPositionToStaffs < ActiveRecord::Migration[7.0]
  def change
    add_column :staffs, :position, :string
  end
end
