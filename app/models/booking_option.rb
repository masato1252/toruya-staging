# == Schema Information
#
# Table name: booking_options
#
#  id              :bigint(8)        not null, primary key
#  user_id         :bigint(8)        not null
#  name            :string           not null
#  display_name    :string
#  minutes         :integer          not null
#  interval        :integer          not null
#  amount_cents    :decimal(, )      not null
#  amount_currency :string           not null
#  tax_include     :boolean          not null
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
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at
# attr_accessor :start_at_date_part, :start_at_time_part

  belongs_to :user

  has_many :menu_relations, class_name: "BookingOptionMenu"
  has_many :booking_option_menus
  has_many :menus, through: :booking_option_menus

  monetize :amount_cents
end
