# frozen_string_literal: true

module Shops
  class Update < ActiveInteraction::Base
    CONTENT_TYPES = %w[image/png image/gif image/jpg image/jpeg].freeze

    object :shop
    hash :params, strip: false do
      # file :logo, default: nil
      # boolean :holiday_working, default: nil
      # string :name, default: nil
      # string :short_name, default: nil
      # string :phone_number, default: nil
      # string :website, default: nil
      # string :email, default: nil
      # hash :address_details, strip: false, default: nil do
      #   string :zip_code, default: nil
      #   string :region, default: nil
      #   string :city, default: nil
      #   string :street1, default: nil
      #   string :street2, default: nil
      # end
    end

    def execute
      logo_params = params.delete(:logo)
      business_schedules = params.delete(:business_schedules)

      shop.transaction do
        if params.present? && shop.update(params)
          errors.merge!(shop.errors)
        end

        if logo_params
          if logo_params.content_type.in?(CONTENT_TYPES) && logo_params.size.between?(0, 1.megabyte)
            shop.logo.attach(logo_params)
          else
            errors.add(:shop, :photo_invalid)
          end
        end

        if shop.holiday_working
          compose(
            BusinessSchedules::Update,
            shop: shop,
            business_state: "opened",
            day_of_week: BusinessSchedule::HOLIDAY_WORKING_WDAY,
            business_schedules: business_schedules
          )
        else
          compose(
            BusinessSchedules::Update,
            shop: shop,
            business_state: "closed",
            day_of_week: BusinessSchedule::HOLIDAY_WORKING_WDAY,
            business_schedules: []
          )
        end
      end

      shop
    end
  end
end
