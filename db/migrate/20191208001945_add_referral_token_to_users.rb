# frozen_string_literal: true

class AddReferralTokenToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :referral_token, :string
    add_index :users, :referral_token, unique: true

    User.find_each do |user|
      user.referral_token ||= Devise.friendly_token[0,10]
      user.save!
    end
  end
end
