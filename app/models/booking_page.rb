# == Schema Information
#
# Table name: booking_pages
#
#  id                      :bigint(8)        not null, primary key
#  user_id                 :bigint(8)        not null
#  shop_id                 :bigint(8)        not null
#  name                    :string           not null
#  title                   :string
#  greeting                :text
#  note                    :text
#  interval                :integer
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  start_at                :datetime
#  end_at                  :datetime
#  overbooking_restriction :boolean          default(TRUE)
#  draft                   :boolean          default(TRUE), not null
#
# Indexes
#
#  index_booking_pages_on_shop_id  (shop_id)
#  index_booking_pages_on_user_id  (user_id)
#

class BookingPage < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at

  has_many :booking_page_options
  has_many :booking_options, through: :booking_page_options
  has_many :booking_page_special_dates

  belongs_to :user
  belongs_to :shop

  scope :active, -> { where(draft: false) }

  def start_time
    start_at || created_at
  end
end
