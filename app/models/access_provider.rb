# frozen_string_literal: true
# == Schema Information
#
# Table name: access_providers
#
#  id              :integer          not null, primary key
#  access_token    :string
#  default_payment :boolean          default(FALSE)
#  email           :string
#  provider        :string
#  publishable_key :string
#  refresh_token   :string
#  uid             :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  user_id         :integer
#
# Indexes
#
#  index_access_providers_on_provider_and_uid  (provider,uid)
#

require "message_encryptor"

class AccessProvider < ApplicationRecord
  PAYMENT_PROVIDERS = %w(stripe_connect square)
  belongs_to :user

  enum provider: {
    stripe_connect: "stripe_connect",
    square: "square",
    google_oauth2: "google_oauth2"
  }

  scope :payment, -> { where(provider: PAYMENT_PROVIDERS) }

  def raw_access_token
    provider.in?(PAYMENT_PROVIDERS) ? MessageEncryptor.decrypt(access_token) : access_token
  end

  def raw_refresh_token
    provider.in?(PAYMENT_PROVIDERS) ? MessageEncryptor.decrypt(refresh_token) : refresh_token
  end

  def square_client
    @client ||= Square::Client.new(
      access_token: raw_access_token,
      environment: Rails.configuration.x.env.production? ? "production" : "sandbox",
      timeout: 10
    )
  end
end
