# frozen_string_literal: true

module SalePages
  class Clone < ActiveInteraction::Base
    object :sale_page

    def execute
      new_sale_page = sale_page.deep_clone(
        only: [
          :content,
          :flow,
          :introduction_video_url,
          :normal_price_amount_cents,
          :product_type,
          :product_id,
          :quantity,
          :recurring_prices,
          :sale_template_variables,
          :sections_context,
          :selling_start_at,
          :selling_end_at,
          :selling_multiple_times_price,
          :selling_price_amount_cents,
          :sale_template_id,
          :staff_id,
          :user_id
        ]
      )
      new_sale_page.assign_attributes(slug: SecureRandom.alphanumeric(10))

      customer_picture_files = sale_page.customer_pictures.map do |customer_picture|
        {
          io: URI.open(Rails.application.routes.url_helpers.url_for(customer_picture)),
          filename: customer_picture.blob.filename.to_s
        }
      end
      new_sale_page.customer_pictures.attach(customer_picture_files)

      content_picture = URI.open(Rails.application.routes.url_helpers.url_for(sale_page.picture))
      new_sale_page.picture.attach(io: content_picture, filename: sale_page.picture.blob.filename.to_s) if sale_page.picture.attached?

      new_sale_page.internal_name = "#{sale_page.internal_name || sale_page.product_name}（のコピー）"

      new_sale_page.save
    end
  end
end
