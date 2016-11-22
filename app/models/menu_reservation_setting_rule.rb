# == Schema Information
#
# Table name: menu_reservation_setting_rules
#
#  id               :integer          not null, primary key
#  menu_id          :integer
#  reservation_type :string
#  start_date       :date
#  end_date         :date
#  repeats          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class MenuReservationSettingRule < ApplicationRecord
  TYPES = %w(date repeating)
  belongs_to :menu

  validates :reservation_type, inclusion: { in: TYPES }, allow_nil: true

  def repeating?
    reservation_type == "repeating"
  end
end
