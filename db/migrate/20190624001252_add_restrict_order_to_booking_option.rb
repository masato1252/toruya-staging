# frozen_string_literal: true

class AddRestrictOrderToBookingOption < ActiveRecord::Migration[5.2]
  def change
    add_column :booking_options, :menu_restrict_order, :boolean, default: false, null: false
  end
end
