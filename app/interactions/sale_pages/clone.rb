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


      new_sale_page.internal_name = "#{sale_page.internal_name || sale_page.product_name} (#{I18n.t("common.copy")})"
      new_sale_page.published = false

      new_sale_page.save

      SalePages::CloneImages.perform_later(sale_page: sale_page, new_sale_page: new_sale_page)
      new_sale_page
    end
  end
end
