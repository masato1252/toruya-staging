class OnlineServiceSerializer
  include JSONAPI::Serializer
  attribute :name, :content
  attribute :solution, &:solution_type

  attribute :company_info do |service|
    case service.company
    when Shop
      ShopSerializer.new(service.company).attributes_hash
    when Profile
      ShopProfileSerializer.new(service.company).attributes_hash
    end
  end

  attribute :upsell_sale_page do |service|
    service.upsell_sale_page_id ? SalePageOptionSerializer.new(service.sale_page).attributes_hash : nil
  end
end
