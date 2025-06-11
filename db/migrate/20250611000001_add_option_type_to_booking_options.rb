class AddOptionTypeToBookingOptions < ActiveRecord::Migration[7.0]
  def change
    add_column :booking_options, :option_type, :string, default: 'primary', null: false
  end
end
