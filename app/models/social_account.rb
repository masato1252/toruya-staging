# frozen_string_literal: true

# == Schema Information
#
# Table name: social_accounts
#
#  id                   :bigint(8)        not null, primary key
#  user_id              :integer          not null
#  channel_id           :string
#  channel_token        :string
#  channel_secret       :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  label                :string
#  basic_id             :string
#  login_channel_id     :string
#  login_channel_secret :string
#
# Indexes
#
#  index_social_accounts_on_user_id_and_channel_id  (user_id,channel_id) UNIQUE
#

require "message_encryptor"

class SocialAccount < ApplicationRecord
  has_many :social_customers, dependent: :destroy
  has_many :social_messages, dependent: :destroy
  has_many :social_rich_menus
  belongs_to :user

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_token = raw_channel_token
      config.channel_secret = raw_channel_secret
    }
  end

  def is_login_available?
    login_channel_id && login_channel_secret
  end

  def bot_data_finished?
    attributes.slice("channel_id", "channel_token", "channel_secret", "basic_id", "label").all? { |attribute, value| value.present? }
  end

  def raw_channel_token
    MessageEncryptor.decrypt(channel_token) if channel_token.present?
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def raw_channel_secret
    MessageEncryptor.decrypt(channel_secret) if channel_secret.present?
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def raw_login_channel_secret
    MessageEncryptor.decrypt(login_channel_secret) if login_channel_secret.present?
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def add_friend_url
    "https://line.me/R/ti/p/#{basic_id}" if basic_id.present?
  end

  def using_line_official_account?
    social_rich_menus.where(social_name: SocialRichMenu::LINE_OFFICIAL_RICH_MENU_KEY).exists?
  end
end
