# == Schema Information
#
# Table name: booking_option_menus
#
#  id                :bigint(8)        not null, primary key
#  booking_option_id :bigint(8)        not null
#  menu_id           :bigint(8)        not null
#  priority          :integer
#  required_time     :integer
#
# Indexes
#
#  index_booking_option_menus_on_booking_option_id  (booking_option_id)
#  index_booking_option_menus_on_menu_id            (menu_id)
#

class BookingOptionMenu < ApplicationRecord
  belongs_to :menu
  belongs_to :booking_option
end
