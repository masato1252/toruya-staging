# frozen_string_literal: true

# == Schema Information
#
# Table name: reservation_setting_menus
#
#  id                     :integer          not null, primary key
#  reservation_setting_id :integer
#  menu_id                :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  reservation_setting_menus_index  (reservation_setting_id,menu_id)
#

class ReservationSettingMenu < ApplicationRecord
  belongs_to :reservation_setting
  belongs_to :menu
end
