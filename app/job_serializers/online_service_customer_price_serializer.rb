class OnlineServiceCustomerPriceSerializer < ActiveJob::Serializers::ObjectSerializer
  def serialize?(argument)
    argument.kind_of?(OnlineServiceCustomerPrice)
  end

  def serialize(online_service_customer_price)
    super(
      "amount_currency" => online_service_customer_price.amount_with_currency.currency.iso_code,
      "amount_fractional" => online_service_customer_price.amount_with_currency.fractional,
      "charge_at" => online_service_customer_price.charge_at&.iso8601,
      "order_id" => online_service_customer_price.order_id
    )
  end

  def deserialize(hash)
    OnlineServiceCustomerPrice.new(
      amount: hash["amount_fractional"],
      currency: hash["amount_currency"],
      charge_at: hash["charge_at"] ? Time.parse(hash["charge_at"]) : nil,
      order_id: hash["order_id"]
    )
  end
end
