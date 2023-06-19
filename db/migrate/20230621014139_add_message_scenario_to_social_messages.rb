class AddMessageScenarioToSocialMessages < ActiveRecord::Migration[7.0]
  def change
    add_column :custom_messages, :nth_time, :integer, default: 1
    add_column :social_user_messages, :scenario, :string
    add_column :social_user_messages, :nth_time, :integer

    add_index :social_user_messages, [:social_user_id, :scenario], name: :message_scenario_index
    remove_index :social_user_messages, :social_user_id
  end
end
