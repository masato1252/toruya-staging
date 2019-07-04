# == Schema Information
#
# Table name: reservation_menus
#
#  id             :bigint(8)        not null, primary key
#  reservation_id :bigint(8)
#  menu_id        :bigint(8)
#  position       :integer
#  required_time  :integer
#
# Indexes
#
#  index_reservation_menus_on_menu_id         (menu_id)
#  index_reservation_menus_on_reservation_id  (reservation_id)
#  reservation_menu_index                     (reservation_id,menu_id)
#

class ReservationMenu < ApplicationRecord
  belongs_to :reservation, required: false
  belongs_to :menu
end
