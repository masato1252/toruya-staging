module TicketProductConcern
  extend ActiveSupport::Concern
  # customer_tickets_quota is a hash, key is customer_ticket_id, value is nth_quota
  # {
  #   customer_ticket_id1 => {
  #     nth_quota: nth_quota1,
  #     product_id: product_id1
  #   },
  #   customer_ticket_id2 => {
  #     nth_quota: nth_quota2,
  #     product_id: product_id2
  #   }
  # }
  def customer_tickets
    @customer_tickets ||= CustomerTicket.where(id: customer_tickets_quota.keys)
  end

  def nth_quota_of_customer_ticket(customer_ticket)
    customer_tickets_quota[customer_ticket.id][:nth_quota]
  end

  def nth_quota_of_product(product)
    # find the nth_quota of the product
    customer_tickets_quota.find { |_customer_ticket_id, quota| quota[:product_id] == product.id }&.dig(1, :nth_quota)
  end

  def all_product_ids_need_to_pay
    # find all the product_id its nth_quota is 1
    using_ticket_product_ids = customer_tickets_quota.select { |_customer_ticket_id, nth_quota| nth_quota[:nth_quota] != 1 }.map { |_customer_ticket_id, nth_quota| nth_quota[:product_id].to_s }
    product_ids - using_ticket_product_ids
  end

  def amount_need_to_pay
    products.where(id: all_product_ids_need_to_pay).sum(&:amount)
  end

  private

  def products
    raise "Please implement this method in the including class"
  end

  def product_ids
    raise "Please implement this method in the including class"
  end

  def booking_amount
    raise "Please implement this method in the including class"
  end
end
