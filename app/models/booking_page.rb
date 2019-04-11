# == Schema Information
#
# Table name: booking_pages
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  shop_id    :bigint(8)        not null
#  name       :string           not null
#  title      :string
#  greeting   :text
#  note       :text
#  interval   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_booking_pages_on_shop_id  (shop_id)
#  index_booking_pages_on_user_id  (user_id)
#

class BookingPage < ApplicationRecord
  has_many :page_options, class_name: "BookingPageOption", foreign_key: :booking_page_id
  has_many :options, class_name: "BookingOption", through: :page_options
end
