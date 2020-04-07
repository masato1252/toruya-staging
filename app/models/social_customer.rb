# == Schema Information
#
# Table name: social_customers
#
#  id                 :bigint(8)        not null, primary key
#  user_id            :bigint(8)        not null
#  customer_id        :bigint(8)
#  social_user_id     :string           not null
#  social_account_id  :integer
#  conversation_state :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_social_customers_on_customer_id  (customer_id)
#  index_social_customers_on_user_id      (user_id)
#

class SocialCustomer < ApplicationRecord
  belongs_to :social_account
end
