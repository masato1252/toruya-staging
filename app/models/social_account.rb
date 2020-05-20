# == Schema Information
#
# Table name: social_accounts
#
#  id             :bigint(8)        not null, primary key
#  user_id        :integer          not null
#  channel_id     :string           not null
#  channel_token  :string           not null
#  channel_secret :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  label          :string
#
# Indexes
#
#  index_social_accounts_on_user_id_and_channel_id  (user_id,channel_id) UNIQUE
#

require "message_encryptor"

class SocialAccount < ApplicationRecord
  validates :label, presence: true
  validates :channel_id, presence: true, uniqueness: true
  validates :channel_token, presence: true
  validates :channel_secret, presence: true

  has_many :social_customers
  belongs_to :user

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_token = raw_channel_token
      config.channel_secret = raw_channel_secret
    }
  end

  def raw_channel_token
    MessageEncryptor.decrypt(channel_token) if channel_token.present?
  end

  def raw_channel_secret
    MessageEncryptor.decrypt(channel_secret) if channel_secret.present?
  end
end
