module ImageUrlHandler
  def self.image_url(image_object)
    if sale_page.picture.attached?
      begin
        picture_variant = sale_page.picture.variant(combine_options: { resize: "750", flatten: true })
        filename = picture_variant.blob.filename.to_s

        if sale_page.picture.service.exist?(picture_variant.key)
          Rails.application.routes.url_helpers.url_for(picture_variant)
        else
          Rails.application.routes.url_helpers.url_for(sale_page.picture)
        end
      rescue ActiveStorage::InvariableError
        Rails.application.routes.url_helpers.url_for(sale_page.picture)
      end
    else
      nil
    end
  end
end
