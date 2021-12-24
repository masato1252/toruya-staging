class OnlineServiceCustomerPrice
  include ActiveAttr::MassAssignment
  include ActiveAttr::Attributes

  attribute :amount
  attribute :charge_at
  attribute :order_id
end

