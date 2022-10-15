# frozen_string_literal: true

module Images
  class Process < ActiveInteraction::Base
    object :image, class: Object # ActiveStorage::Attached
    string :resize

    def execute
      begin
        picture_variant = image.variant(combine_options: { resize: resize, flatten: true })
        filename = picture_variant.blob.filename.to_s

        if image.service.exist?(picture_variant.key)
          Rails.application.routes.url_helpers.url_for(picture_variant)
        else
          Rails.application.routes.url_helpers.url_for(image)
        end
      rescue ActiveStorage::InvariableError
        Rails.application.routes.url_helpers.url_for(image)
      end
    rescue
      nil
    end
  end
end
