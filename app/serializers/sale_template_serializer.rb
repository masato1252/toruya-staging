class SaleTemplateSerializer
  include JSONAPI::Serializer
  attribute :id, :edit_body, :view_body
end
