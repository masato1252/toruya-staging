# frozen_string_literal: true
# == Schema Information
#
# Table name: access_providers
#
#  id              :integer          not null, primary key
#  access_token    :string
#  refresh_token   :string
#  provider        :string
#  uid             :string
#  user_id         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  email           :string
#  publishable_key :string
#
# Indexes
#
#  index_access_providers_on_provider_and_uid  (provider,uid)
#

require "message_encryptor"

class AccessProvider < ApplicationRecord
  belongs_to :user

  def raw_access_token
    provider == "stripe_connect" ? MessageEncryptor.decrypt(access_token) : access_token
  end
end
