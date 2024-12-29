# frozen_string_literal: true
# == Schema Information
#
# Table name: social_customers
#
#  id                      :bigint           not null, primary key
#  conversation_state      :integer          default("bot")
#  is_owner                :boolean          default(FALSE)
#  locale                  :string           default("ja")
#  social_rich_menu_key    :string
#  social_user_name        :string
#  social_user_picture_url :string
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  customer_id             :bigint
#  social_account_id       :integer
#  social_user_id          :string           not null
#  user_id                 :bigint           not null
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

  def language
    I18n.available_locales.include?(locale&.to_sym) ? locale.to_sym : I18n.default_locale
  end
end
