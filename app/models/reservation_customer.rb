# == Schema Information
#
# Table name: reservation_customers
#
#  id             :integer          not null, primary key
#  reservation_id :integer          not null
#  customer_id    :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_reservation_customers_on_reservation_id_and_customer_id  (reservation_id,customer_id) UNIQUE
#

class ReservationCustomer < ApplicationRecord
  belongs_to :reservation, counter_cache: :count_of_customers
  belongs_to :customer, touch: true
end
