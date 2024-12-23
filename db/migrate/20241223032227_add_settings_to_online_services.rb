class AddSettingsToOnlineServices < ActiveRecord::Migration[7.0]
  def change
    add_column :online_services, :settings, :jsonb, default: {}, null: false
    OnlineService.update_all(settings: { customer_address_required: true })
  end
end