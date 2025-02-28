# frozen_string_literal: true

module Profiles
  class UpdateAttribute < ActiveInteraction::Base
    object :profile
    string :update_attribute

    hash :attrs, default: nil do
      string :last_name, default: nil
      string :first_name, default: nil
      string :phonetic_last_name, default: nil
      string :phonetic_first_name, default: nil
      string :company_name, default: nil
      string :company_phone_number, default: nil
      string :company_email, default: nil
      string :website, default: nil
      hash :company_address_details, default: nil, strip: false
      file :logo, default: nil
    end

    def execute
      profile.with_lock do
        case update_attribute
        when "name"
          profile.update!(
            last_name: attrs[:last_name],
            first_name: attrs[:first_name],
            phonetic_last_name: attrs[:phonetic_last_name],
            phonetic_first_name: attrs[:phonetic_first_name]
          )

          staff = profile.user.current_staff(profile.user)
          staff.update!(
            last_name: attrs[:last_name],
            first_name: attrs[:first_name],
            phonetic_last_name: attrs[:phonetic_last_name],
            phonetic_first_name: attrs[:phonetic_first_name]
          )
        when "company_name", "company_phone_number", "company_email", "website"
          profile.update(attrs.slice(update_attribute))
        when "company_address_details"
          address = Address.new(attrs[:company_address_details])

          if address.invalid?
            errors.add(:attrs, :address_invalid)
          else
            profile.update(
              company_address: address.pure_address,
              company_zip_code: address.zip_code,
              company_address_details: address.as_json
            )
          end
        when "logo"
          logo_params = attrs[:logo]

          if logo_params
            if logo_params.content_type.in?(Shops::Update::CONTENT_TYPES) && logo_params.size.between?(0, 0.1.megabyte)
              profile.logo.attach(logo_params)
            else
              errors.add(:profile, :logo_invalid)
            end
          end
        end

        if profile.errors.present?
          errors.merge!(profile.errors)
        end

        profile
      end
    end
  end
end