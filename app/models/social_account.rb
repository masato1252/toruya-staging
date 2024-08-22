# frozen_string_literal: true

# == Schema Information
#
# Table name: social_accounts
#
#  id                   :bigint           not null, primary key
#  channel_secret       :string
#  channel_token        :string
#  label                :string
#  login_channel_secret :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  basic_id             :string
#  channel_id           :string
#  login_channel_id     :string
#  user_id              :integer          not null
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
  has_one :current_rich_menu, -> { current }, class_name: "SocialRichMenu"
  belongs_to :user

  def client
    if raw_channel_token && raw_channel_secret
      @client ||= Line::Bot::Client.new { |config|
        config.channel_token = raw_channel_token
        config.channel_secret = raw_channel_secret
      }
    end
  end

  def line_settings_finished?
    is_login_available? && bot_data_finished?
  end

  def line_settings_verified?
    login_api_verified? && message_api_verified?
  end

  def login_api_verified?
    is_login_available? && user.owner_social_customer.present?
  end

  def channel_secret_correctness?
    raw_channel_secret.present? && raw_channel_secret != raw_login_channel_secret
  end

  def message_api_verified?
    bot_data_finished? && social_messages.where(
      social_customer: user.owner_social_customer,
      raw_content: user.social_user.social_service_user_id
    ).from_customer.exists?
  end

  def is_login_available?
    login_channel_id && login_channel_secret && raw_login_channel_secret
  end

  def bot_data_finished?
    attributes.slice("channel_id", "channel_token", "channel_secret", "basic_id", "label").all? { |attribute, value| value.present? } && raw_channel_token.present? && raw_channel_secret.present?
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
    current_rich_menu&.official?
  end

  def current_rich_menu_key
    current_rich_menu&.social_name || SocialAccounts::RichMenus::CustomerReservations::KEY
  end
end
