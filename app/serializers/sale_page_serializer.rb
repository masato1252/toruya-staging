# frozen_string_literal: true

class SalePageSerializer
  include JSONAPI::Serializer
  attribute :id, :introduction_video_url, :flow, :end_time, :start_time, :sections_context, :solution_type, :normal_price

  attribute :content do |sale_page|
    picture_url = Images::Process.run!(image: sale_page.picture, resize: "750")

    sale_page.content.merge(picture_url: picture_url)
  end

  attribute :internal_name do |sale_page|
    sale_page.internal_name.presence || sale_page.product_name
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

  attribute :normal_price_option do |object|
    if object.normal_price_amount_cents
      {
        price_type: "cost",
        price_amount: object.normal_price_amount.fractional,
        price_amount_format: object.normal_price_amount.format
      }
    else
      {
        price_type: "free"
      }
    end
  end

  attribute :reviews do |object|
    if object.sections_context&.[]("reviews").blank?
      nil
    else
      picture_url_mapping =
        object.customer_pictures.each_with_object({}) do |customer_picture, h|
          picture_variant = customer_picture.variant( combine_options: { resize: "360", flatten: true })
          filename = picture_variant.blob.filename.to_s

          picture_url =
            if customer_picture.service.exist?(picture_variant.key)
              Rails.application.routes.url_helpers.url_for(picture_variant)
            else
              Rails.application.routes.url_helpers.url_for(customer_picture)
            end

          h[filename] = picture_url
        end

      object.sections_context["reviews"].map do |review|
        review.merge!(picture_url: picture_url_mapping[review["filename"]])
      end
    end
  end
end
