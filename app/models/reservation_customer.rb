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

class ReservationCustomer < ApplicationRecord
  belongs_to :reservation, counter_cache: :count_of_customers
  belongs_to :customer, touch: true
end
