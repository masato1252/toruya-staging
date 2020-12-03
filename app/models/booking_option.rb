# == Schema Information
#
# Table name: booking_options
#
#  id                  :bigint(8)        not null, primary key
#  user_id             :bigint(8)        not null
#  name                :string           not null
#  display_name        :string
#  minutes             :integer          not null
#  amount_cents        :decimal(, )      not null
#  amount_currency     :string           not null
#  tax_include         :boolean          not null
#  start_at            :datetime
#  end_at              :datetime
#  memo                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  menu_restrict_order :boolean          default(FALSE), not null
#
# Indexes
#
#  index_booking_options_on_user_id  (user_id)
#

class BookingOption < ApplicationRecord
  include DateTimeAccessor
  date_time_accessor :start_at, :end_at, accessor_only: true
# attr_accessor :start_at_date_part, :start_at_time_part

  belongs_to :user

  has_many :menu_relations, class_name: "BookingOptionMenu"
  has_many :booking_option_menus, -> { order("booking_option_menus.priority") }
  has_many :menus, through: :booking_option_menus

  monetize :amount_cents

  scope :started, -> { where(start_at: nil).or(where("booking_options.start_at < ?", Time.current)) }
  scope :end_yet, -> { where(end_at: nil).or(where("booking_options.end_at >= ?", Time.current)) }
  scope :active, -> { started.end_yet }

  def start_time
    start_at || created_at
  end

  def possible_menus_order_groups
    base_booking_option_menus = self.booking_option_menus.includes("menu").order("priority").to_a

    if menu_restrict_order
      [base_booking_option_menus]
    else
      # XXX: Different menus orders will affect staffs could handle it or not,
      #      so test all the possibility when booking option doesn't restrict menu order
      base_booking_option_menus.permutation(base_booking_option_menus.size)
    end
  end
end
