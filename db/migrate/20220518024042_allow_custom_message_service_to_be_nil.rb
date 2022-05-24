class AllowCustomMessageServiceToBeNil < ActiveRecord::Migration[6.0]
  def change
    change_column_null :custom_messages, :service_id, true
    change_column_null :custom_messages, :service_type, true
  end
end
