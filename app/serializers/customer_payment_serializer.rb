# frozen_string_literal: true

class CustomerPaymentSerializer
  include JSONAPI::Serializer
  attribute :id, :state

  attribute :year do |object|
    object.charge_at&.year || object.created_at.year
  end

  attribute :month_date do |object|
    I18n.l(object.charge_at || object.created_at, format: :month_day_wday)
  end

  attribute :time do |object|
    I18n.l(object.charge_at || object.created_at, format: :hour_minute)
  end

  attribute :product_name do |object|
    case object.product
    when OnlineServiceCustomerRelation
      object.product.online_service.name
    when ReservationCustomer
      object.product.booking_option.name
    end
  end

  attribute :amount do |object|
    object.amount.format
  end
end
