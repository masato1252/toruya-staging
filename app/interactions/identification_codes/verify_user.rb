# frozen_string_literal: true

module IdentificationCodes
  class VerifyUser < ActiveInteraction::Base
    object :social_user
    string :phone_number
    string :uuid
    string :code, default: nil
    string :staff_token, default: nil
    string :consultant_token, default: nil

    validate :validate_phone_number_present

    def execute
      I18n.with_locale(locale) do
        identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code, locale: locale)

        formatted_phone = Phonelib.parse(phone_number).international(false)
        if identification_code && (user = User.where(phone_number: formatted_phone).take)
          compose(SocialUsers::Connect, social_user: social_user, user: user, change_rich_menu: true)
          compose(StaffAccounts::ConnectUser, token: staff_token, user: social_user.user) if staff_token.present?
          compose(StaffAccounts::CreateConsultant, token: consultant_token, client: user) if consultant_token.present?

          # XXX: When user already filled in the company information, but verified code, again.
          # This means it is a sign-in behavior
          if user.profile.address.present?
            Notifiers::Users::LineUserSignedIn.run(receiver: social_user)
          end
        end

        identification_code
      end
    end

    private

    def validate_phone_number_present
      if phone_number.blank?
        errors.add(:phone_number, :present)
      end
    end

    def locale
      social_user.locale || I18n.locale
    end
  end
end
