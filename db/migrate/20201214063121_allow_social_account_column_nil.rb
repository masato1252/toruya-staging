# frozen_string_literal: true

class AllowSocialAccountColumnNil < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:social_accounts, :channel_id, true)
    change_column_null(:social_accounts, :channel_token, true)
    change_column_null(:social_accounts, :channel_secret, true)
  end
end
