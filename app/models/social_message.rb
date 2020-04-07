# == Schema Information
#
# Table name: social_messages
#
#  id                 :bigint(8)        not null, primary key
#  social_account_id  :integer          not null
#  social_customer_id :integer          not null
#  staff_id           :integer
#  raw_content        :text
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  social_message_customer_index  (social_account_id,social_customer_id)
#

class SocialMessage < ApplicationRecord
end
