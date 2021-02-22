# frozen_string_literal: true

class SalePageSerializer
  include JSONAPI::Serializer

  attribute :content do |sale_page|
    sale_page.content.merge(
      picture_url: Rails.application.routes.url_helpers.url_for(sale_page.picture.variant(combine_options: {
        resize: "750",
        flatten: true
      }))
    )
  end

  attribute :staff do |sale_page|
    StaffSerializer.new(sale_page.staff).attributes_hash
  end

  attribute :template do |sale_page|
    sale_page.sale_template.view_body
  end

  attribute :template_variables do |sale_page|
    sale_page.sale_template_variables
  end

  attribute :social_account_add_friend_url do |sale_page|
    sale_page.user.social_accounts.first&.add_friend_url
  end
end
