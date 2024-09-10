class CustomerTickets::Update < ActiveInteraction::Base
  object :customer_ticket
  date :expire_at

  def execute
    customer_ticket.update(expire_at: expire_at.to_datetime.end_of_day)
  end
end 