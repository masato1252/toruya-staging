module Shops
  class Update < ActiveInteraction::Base
    CONTENT_TYPES = %w[image/png image/gif].freeze

    object :shop
    hash :params, strip: false

    def execute
      logo_params = params.delete(:logo)

      shop.transaction do
        if shop.update(params)

          if logo_params
            if logo_params.content_type.in?(CONTENT_TYPES) && logo_params.size.between?(0, 0.05.megabyte)
              shop.logo.attach(logo_params)
            else
              errors.add(:shop, :photo_invalid)
            end
          end
        else
          errors.merge!(shop.errors)
        end
      end
    end
  end
end
