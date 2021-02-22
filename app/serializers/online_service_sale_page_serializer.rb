# frozen_string_literal: true

class OnlineServiceSalePageSerializer < SalePageSerializer
  attribute :price, &:selling_price_amount_cents
  attribute :normal_price, &:normal_price_amount_cents
  attribute :quantity

  attribute :product do |object|
    OnlineServiceSerializer.new(object.product).attributes_hash
  end

  attribute :introduction_video do |object|
    { url: object.introduction_video_url }
  end

  attribute :is_started do |object|
    object.selling_start_at.nil? || Time.current > object.selling_start_at
  end

  attribute :is_ended do |object|
    object.selling_end_at && Time.current > object.selling_end_at
  end

  attribute :purchase_url do
    "#"
  end
end
