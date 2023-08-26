# frozen_string_literal: true

module Images
  class Process < ActiveInteraction::Base
    object :image, class: Object # ActiveStorage::Attached
    string :resize

    def execute
      return unless image.attached?

      begin
        picture_variant = image.variant(resize: resize, flatten: true)
        filename = picture_variant.blob.filename.to_s

        if image.service.exist?(picture_variant.key)
          Rails.application.routes.url_helpers.url_for(picture_variant)
        else
          Rails.application.routes.url_helpers.url_for(image)
        end
      rescue ActiveStorage::InvariableError
        Rails.application.routes.url_helpers.url_for(image)
      rescue => e
        Rollbar.error(e)
        Rails.application.routes.url_helpers.url_for(image)
      end
    rescue
      nil
    end
  end
end
