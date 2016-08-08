# == Schema Information
#
# Table name: reservations
#
#  id         :integer          not null, primary key
#  shop_id    :integer
#  menu_id    :integer
#  start_time :datetime
#  end_time   :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Reservation < ApplicationRecord
end
