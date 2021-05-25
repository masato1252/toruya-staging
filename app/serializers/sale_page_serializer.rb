# frozen_string_literal: true

class SalePageSerializer
  include JSONAPI::Serializer
  attribute :id, :introduction_video_url, :flow, :end_time, :start_time, :sections_context, :solution_type

  attribute :content do |sale_page|
    sale_page.content.merge(
      picture_url: sale_page.picture.attached? ? Rails.application.routes.url_helpers.url_for(sale_page.picture.variant(combine_options: { resize: "750", flatten: true })) : nil
    )
  end

  attribute :staff do |sale_page|
    StaffSerializer.new(sale_page.staff).attributes_hash
  end

  attribute :template do |sale_page|
    sale_page.sale_template.view_body
  end

  attribute :edit_template do |sale_page|
    sale_page.sale_template.edit_body
  end

  attribute :template_variables do |sale_page|
    sale_page.sale_template_variables
  end

  attribute :social_account_add_friend_url do |sale_page|
    sale_page.user.social_accounts.first&.add_friend_url
  end

  attribute :introduction_video do |object|
    { url: object.introduction_video_url }
  end
end
