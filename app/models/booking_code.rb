# == Schema Information
#
# Table name: booking_codes
#
#  id              :bigint(8)        not null, primary key
#  uuid            :string
#  code            :string
#  booking_page_id :integer
#  customer_id     :integer
#  reservation_id  :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_booking_codes_on_booking_page_id_and_uuid_and_code  (booking_page_id,uuid,code) UNIQUE
#

class BookingCode < ApplicationRecord
end
