# frozen_string_literal: true

class MembershipSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :slug, :tags

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.user.shops.first || service.company).attributes_hash
  end
end
