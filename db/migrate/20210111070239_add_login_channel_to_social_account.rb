# frozen_string_literal: true

class AddLoginChannelToSocialAccount < ActiveRecord::Migration[5.2]
  def change
    add_column :social_accounts, :login_channel_id, :string
    add_column :social_accounts, :login_channel_secret, :string
  end
end
