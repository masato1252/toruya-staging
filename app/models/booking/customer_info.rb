module Booking
  class CustomerInfo
    include ActiveAttr::MassAssignment
    include ActiveAttr::Attributes

    attribute :last_name
    attribute :first_name
    attribute :phonetic_last_name
    attribute :phonetic_first_name
    attribute :phone_number
    attribute :email
    attribute :address_details
  end
end
