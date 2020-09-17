module IdentificationCodes
  class VerifyUser < ActiveInteraction::Base
    object :social_user
    string :phone_number
    string :uuid
    string :code, default: nil

    def execute
      identification_code = compose(IdentificationCodes::Verify, uuid: uuid, code: code)

      if identification_code && (user = User.where(phone_number: phone_number).take)
        compose(SocialUsers::Connect, social_user: social_user, user: user)
      end

      identification_code
    end
  end
end
