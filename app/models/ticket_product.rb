# == Schema Information
#
# Table name: ticket_products
#
#  id           :bigint           not null, primary key
#  product_type :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  product_id   :bigint           not null
#  ticket_id    :bigint           not null
#
# Indexes
#
#  index_ticket_products_on_product    (product_type,product_id)
#  index_ticket_products_on_ticket_id  (ticket_id)
#
class TicketProduct < ApplicationRecord
  belongs_to :ticket
  belongs_to :product, polymorphic: true
end
