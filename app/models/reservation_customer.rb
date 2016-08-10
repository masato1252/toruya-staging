# == Schema Information
#
# Table name: reservation_customers
#
#  id             :integer          not null, primary key
#  reservation_id :integer
#  customer_id    :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class ReservationCustomer < ApplicationRecord
  belongs_to :reservation
  belongs_to :customer
end
