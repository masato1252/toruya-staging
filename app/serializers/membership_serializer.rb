# frozen_string_literal: true

class MembershipSerializer
  include JSONAPI::Serializer
  attribute :id, :name, :slug, :tags

  attribute :company_info do |service|
    CompanyInfoSerializer.new(service.company).attributes_hash
  end

  attribute :tags do |service|
    service.tags.prepend(Episodes::Tagged::ALL)
  end
end
