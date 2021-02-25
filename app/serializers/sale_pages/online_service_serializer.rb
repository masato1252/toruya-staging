# frozen_string_literal: true


class SalePages::OnlineServiceSerializer < SalePageSerializer
  include SalePages::OnlineServiceProductPart
  attribute :quantity

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
