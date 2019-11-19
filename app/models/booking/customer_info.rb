# customer_info#attributes
# The key has value when it was changed, otherwise, it is nil.
#
# {
#   "last_name" => nil,
#   "first_name" => "guorong1",
#   "phonetic_last_name" => nil,
#   "phonetic_first_name" => "wqeqwe2",
#   "phone_number" => "88691081903",
#   "email" => "lake.ilakela@gmail.com4",
#   "address_details" => {
#     "postcode" => "5555555",
#     "region" => "岩手県6",
#     "city" => "7",
#     "street1" => "4F.-38",
#     "street2" => " No.125, Sinsing StTainan9"
#   }
# }

module Booking
  class CustomerInfo
    ADDRESS_DETAILS_ORDER = %w(postcode region city street1 street2).freeze
    include ActiveAttr::MassAssignment
    include ActiveAttr::Attributes

    attribute :last_name
    attribute :first_name
    attribute :phonetic_last_name
    attribute :phonetic_first_name
    attribute :phone_number
    attribute :email
    attribute :address_details

    def sorted_address_details
      address_details&.compact.present? ? Hashie::Mash.new(Hash[address_details.compact.sort_by { |key, _| ADDRESS_DETAILS_ORDER.index(key) }]) : {}
    end

    def personal_info_attributes
      attributes.reject {|k, _| k == "address_details" }.compact
    end

    def google_data_attributes
      {
        phone_number: phone_number,
        email: email,
        address_details: address_details&.compact
      }.compact
    end

    def name_attributes
      {
        last_name: last_name,
        first_name: first_name,
        phonetic_last_name: phonetic_last_name,
        phonetic_first_name: phonetic_first_name
      }.compact
    end
  end
end
