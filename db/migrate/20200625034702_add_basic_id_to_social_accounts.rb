# frozen_string_literal: true

class AddBasicIdToSocialAccounts < ActiveRecord::Migration[5.2]
  def change
    add_column :social_accounts, :basic_id, :string
  end
end
