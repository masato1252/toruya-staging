# frozen_string_literal: true

module Profiles
  class UpdateShopInfo < ActiveInteraction::Base
    object :user
    object :social_user
    hash :params do
      string :zip_code
      string :region
      string :city
      string :street1, default: nil
      string :street2, default: nil
    end

    validate :validate_address

    def execute
      ApplicationRecord.transaction do
        user.profile.update!(
          params.merge!(
            address: address.pure_address,
            company_address: address.pure_address,
            company_zip_code: params[:zip_code],
            phone_number: user.phone_number,
            company_phone_number: user.phone_number,
            email: user.email,
            company_name: "#{user.name} #{I18n.t("common.of")}#{I18n.t("common.shop")}",
            company_address_details: address.as_json,
            personal_address_details: address.as_json
          )
        )
        # XXX: The user and social_user was connected, what I want to do is change_rich_menu here
        compose(SocialUsers::Connect, user: user, social_user: social_user, change_rich_menu: true)
        Users::CreateDefaultSettings.run(user: user)
        Notifiers::LineUserSignedUp.perform_later(receiver: social_user)
        Notifiers::VideoForUserCreatedShop.perform_later(receiver: social_user)
      end
    end

    private

    def validate_address
      if address.invalid?
        errors.add(:params, :address_invalid)
      end
    end

    def address
      @address ||= Address.new(params)
    end
  end
end
