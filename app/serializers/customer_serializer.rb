# == Schema Information
#
# Table name: customers
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  contact_group_id         :integer
#  rank_id                  :integer
#  last_name                :string
#  first_name               :string
#  phonetic_last_name       :string
#  phonetic_first_name      :string
#  custom_id                :string
#  memo                     :text
#  address                  :string
#  google_uid               :string
#  google_contact_id        :string
#  google_contact_group_ids :string           default([]), is an Array
#  birthday                 :date
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  updated_by_user_id       :integer
#  email_types              :string
#  deleted_at               :datetime
#  reminder_permission      :boolean          default(FALSE)
#
# Indexes
#
#  customer_names_on_first_name_idx           (first_name) USING gin
#  customer_names_on_last_name_idx            (last_name) USING gin
#  customer_names_on_phonetic_first_name_idx  (phonetic_first_name) USING gin
#  customer_names_on_phonetic_last_name_idx   (phonetic_last_name) USING gin
#  customers_basic_index                      (user_id,contact_group_id,deleted_at)
#  customers_google_index                     (user_id,google_uid,google_contact_id) UNIQUE
#  jp_name_index                              (user_id,phonetic_last_name,phonetic_first_name)
#

class CustomerSerializer
  include FastJsonapi::ObjectSerializer
  attribute :created_at

  attribute :id do |customer|
    customer.social_user_id
  end

  attribute :name do |customer|
    customer.social_user_name
  end

  attribute :new_messages_count do |customer|
    customer.social_messages.unread.count
  end

  attribute :last_message_at do |customer|
    customer.social_messages.last&.created_at
  end
end
