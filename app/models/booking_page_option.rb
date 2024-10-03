# frozen_string_literal: true

# == Schema Information
#
# Table name: booking_page_options
#
#  id                     :bigint           not null, primary key
#  online_payment_enabled :boolean          default(FALSE)
#  position               :integer          default(0)
#  booking_option_id      :bigint           not null
#  booking_page_id        :bigint           not null
#
# Indexes
#
#  index_booking_page_options_on_booking_option_id  (booking_option_id)
#  index_booking_page_options_on_booking_page_id    (booking_page_id)
#
class BookingPageOption < ApplicationRecord
  belongs_to :booking_page
  belongs_to :booking_option
  
  def payment_solution
    Users::PaymentSolution.run!(user: booking_page.user, provider: booking_page.payment_provider)
  end

  def is_online_payment?
    online_payment_enabled && !booking_option.cash_pay_required?
  end
end
