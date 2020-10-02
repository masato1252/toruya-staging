module IdentificationCodes
  class VerifyUser < ActiveInteraction::Base
    object :social_user
    string :phone_number
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)

      if identification_code && (user = User.where(phone_number: phone_number).take)
        compose(SocialUsers::Connect, social_user: social_user, user: user, change_rich_menu: user.profile.address.present?)

        # XXX: When user already filled in the company infomration, but verified code, again.
        # This means it is a sign-in behavior
        if user.profile.address.present?
          Notifiers::LineUserSignedIn.run(receiver: social_user)
        end
      end

      identification_code
    end
  end
end
