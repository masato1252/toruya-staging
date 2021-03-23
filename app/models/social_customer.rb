# frozen_string_literal: true
# == Schema Information
#
# Table name: social_customers
#
#  id                      :bigint(8)        not null, primary key
#  user_id                 :bigint(8)        not null
#  customer_id             :bigint(8)
#  social_account_id       :integer
#  social_user_id          :string           not null
#  social_user_name        :string
#  social_user_picture_url :string
#  conversation_state      :integer          default("bot")
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  social_rich_menu_key    :string
#
# Indexes
#
#  index_social_customers_on_customer_id           (customer_id)
#  index_social_customers_on_social_rich_menu_key  (social_rich_menu_key)
#  social_customer_unique_index                    (user_id,social_account_id,social_user_id) UNIQUE
#

class SocialCustomer < ApplicationRecord
  has_many :social_messages
  belongs_to :social_account
  belongs_to :user
  belongs_to :customer, optional: true, touch: true

  delegate :client, to: :social_account

  enum conversation_state: {
    bot: 0,
    one_on_one: 1,
  }
end
