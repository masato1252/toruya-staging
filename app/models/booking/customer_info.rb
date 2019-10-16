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
    # postcode: "7107108"
    # region: "岩手県"
    # city: "Tainan"
    # street1: 続き住所
    # street2: 建物名／部屋番号
    def sorted_address_details
      Hash[address_details.sort_by { |key, _| ADDRESS_DETAILS_ORDER.index(key) }]
    end
  end
end
