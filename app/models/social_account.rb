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
#
# Indexes
#
#  index_social_accounts_on_user_id_and_channel_id  (user_id,channel_id)
#

class SocialAccount < ApplicationRecord
  belongs_to :user

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_token = channel_token
      config.channel_secret = channel_secret
    }
  end
end
