class Address
  include ActiveAttr::Model

  attribute :zip_code
  attribute :region
  attribute :city
  attribute :street1
  attribute :street2

  validates :zip_code, :region, :city, :presence => true

  def display_address
    "〒#{zip_code} #{pure_address}"
  end

  def pure_address
    "#{region}#{city}#{street1}#{street2}"
  end
end
