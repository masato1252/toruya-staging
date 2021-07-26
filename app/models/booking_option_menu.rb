# frozen_string_literal: true

# == Schema Information
#
# Table name: booking_option_menus
#
#  id                :bigint           not null, primary key
#  priority          :integer
#  required_time     :integer
#  booking_option_id :bigint           not null
#  menu_id           :bigint           not null
#
# Indexes
#
#  index_booking_option_menus_on_booking_option_id  (booking_option_id)
#  index_booking_option_menus_on_menu_id            (menu_id)
#

class BookingOptionMenu < ApplicationRecord
  default_value_for :priority, 0

  belongs_to :menu
  belongs_to :booking_option
end
