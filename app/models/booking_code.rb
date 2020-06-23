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

# Booking code are used in online booking and line customer identification
# If BookingCode is from online, it had booking page id, it would have customer_id and reservation_id when it was identified
# If BookingCode is from line customer identification, it had customer_id without booking_page_id and reservation_id. When it was identified, its updated_at would be changed.
class BookingCode < ApplicationRecord
end
