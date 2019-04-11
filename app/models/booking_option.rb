# == Schema Information
#
# Table name: booking_options
#
#  id              :bigint(8)        not null, primary key
#  user_id         :bigint(8)        not null
#  name            :string           not null
#  display_name    :string
#  minutes         :integer
#  interval        :integer
#  amount_cents    :decimal(, )
#  amount_currency :string
#  tax_include     :boolean
#  start_at        :datetime
#  end_at          :datetime
#  memo            :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_booking_options_on_user_id  (user_id)
#

class BookingOption < ApplicationRecord
  has_many :menu_relations, class_name: "BookingOptionMenu"
  has_many :booking_option_menus
  has_many :menus, through: :booking_option_menus
end
