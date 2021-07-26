# frozen_string_literal: true

# == Schema Information
#
# Table name: reservation_menus
#
#  id             :bigint           not null, primary key
#  position       :integer
#  required_time  :integer
#  menu_id        :bigint
#  reservation_id :bigint
#
# Indexes
#
#  index_reservation_menus_on_menu_id  (menu_id)
#  reservation_menu_index              (reservation_id,menu_id)
#

class ReservationMenu < ApplicationRecord
  belongs_to :reservation, required: false
  belongs_to :menu
end
