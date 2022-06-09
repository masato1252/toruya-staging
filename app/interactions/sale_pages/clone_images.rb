# frozen_string_literal: true

module SalePages
  class CloneImages < ActiveInteraction::Base
    object :sale_page
    object :new_sale_page, class: SalePage

    def execute
      customer_picture_files = sale_page.customer_pictures.map do |customer_picture|
        {
          io: URI.open(Rails.application.routes.url_helpers.url_for(customer_picture)),
          filename: customer_picture.blob.filename.to_s
        }
      end
      new_sale_page.customer_pictures.attach(customer_picture_files)

      content_picture = URI.open(Rails.application.routes.url_helpers.url_for(sale_page.picture))
      new_sale_page.picture.attach(io: content_picture, filename: sale_page.picture.blob.filename.to_s) if sale_page.picture.attached?

      new_sale_page.save
      new_sale_page
    end
  end
end
