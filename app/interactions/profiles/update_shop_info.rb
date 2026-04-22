# frozen_string_literal: true

module Profiles
  class UpdateShopInfo < ActiveInteraction::Base
    object :user
    object :social_user
    hash :params do
      string :company_name, default: nil
      string :company_email, default: nil
      string :company_phone_number, default: nil
      string :zip_code, default: nil
      string :region, default: nil
      string :city, default: nil
      string :street1, default: nil
      string :street2, default: nil
    end

    validate :required_fields_present

    def execute
      ApplicationRecord.transaction do
        user.profile.update!(
          params.merge(
            address: address.pure_address,
            company_address: address.pure_address,
            company_zip_code: params[:zip_code],
            phone_number: user.phone_number,
            company_phone_number: params[:company_phone_number].presence || user.phone_number,
            email: user.email.presence || params[:company_email],
            company_email: params[:company_email],
            company_name: params[:company_name],
            company_address_details: address.as_json,
            personal_address_details: address.as_json
          )
        )
        # XXX: The user and social_user was connected, what I want to do is change_rich_menu here
        compose(SocialUsers::Connect, user: user, social_user: social_user, change_rich_menu: true)
        Users::CreateDefaultSettings.run(user: user)
        user.shops.each do |shop|
          Shops::UpdateFromProfile.run!(shop: shop)
        end
        Notifiers::Users::MessageForUserCreatedShop.perform_later(receiver: social_user)
        Notifiers::Users::VideoForUserCreatedShop.perform_later(receiver: social_user)
      end
    end

    private

    def required_fields_present
      errors.add(:company_name, :blank) if params[:company_name].blank?
      errors.add(:company_email, :blank) if params[:company_email].blank?
      errors.add(:zip_code, :blank) if params[:zip_code].blank?
      errors.add(:region, :blank) if params[:region].blank?
      errors.add(:city, :blank) if params[:city].blank?
    end

    def address
      @address ||= Address.new(params)
    end
  end
end
