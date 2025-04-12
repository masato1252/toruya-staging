# frozen_string_literal: true

module Shops
  class UpdateFromProfile < ActiveInteraction::Base
    object :shop

    def execute
      return errors.add(:profile, :not_found) unless shop.user
      profile = shop.user.profile
      return errors.add(:profile, :not_found) unless profile

      shop.transaction do
        shop.update!(
          name: profile.company_name,
          short_name: profile.company_name,
          phone_number: profile.company_phone_number,
          email: profile.company_email,
          website: profile.website,
          zip_code: profile.company_zip_code,
          address: profile.company_address,
          address_details: profile.company_address_details
        )

        # Copy logo if profile has one
        if profile.logo.attached?
          begin
            content_picture = URI.open(Rails.application.routes.url_helpers.url_for(profile.logo))
            shop.logo.attach(io: content_picture, filename: profile.logo.blob.filename.to_s) if content_picture.present?
          rescue StandardError => e
            errors.add(:logo, :copy_failed)
          end
        end

        shop
      end
    end
  end
end