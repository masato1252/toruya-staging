class ShopProfileSerializer
  include JSONAPI::Serializer
  attribute :id

  attribute :label do
    "企業情報"
  end

  attribute :name do |profile|
    profile.company_name
  end

  attribute :short_name do |profile|
    profile.company_name
  end

  attribute :address do |profile|
    profile.company_full_address
  end

  attribute :phone_number do |profile|
    profile.company_phone_number
  end
end
