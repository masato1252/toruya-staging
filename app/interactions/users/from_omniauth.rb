# frozen_string_literal: true

module Users
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    string :referral_token, default: nil
    string :social_service_user_id, default: nil

    def execute
      user = User.find_by(email: auth.info.email) ||
        AccessProvider.where(provider: auth[:provider], uid: auth[:uid]).first.try(:user) ||
        User.where(email: auth.info.email).build(password: Devise.friendly_token[0, 20])

      user.email = auth.info.email.presence || user.email
      user.skip_confirmation!
      user.skip_confirmation_notification!
      user.referral_token ||= Devise.friendly_token[0,5]

      loop do
        if User.where(referral_token: user.referral_token).where.not(id: user.id).exists?
          user.referral_token = Devise.friendly_token[0,5]
        else
          break
        end
      end

      if user.new_record? &&
          referral_token && (referee = User.find_by(referral_token: referral_token)) &&
          referee.business_member?
        compose(Referrals::Build, referee: referee, referrer: user)
        Notifiers::Users::LineUserSignedUp.run(receiver: user)
        # TODO: Send sequence message
      end
      compose(GoogleOauth::Create, user: user, auth: auth)
      compose(Users::BuildDefaultData, user: user)
      user.save!

      if social_service_user_id
        compose(SocialUsers::Connect, user: user, social_user: SocialUser.find_by!(social_service_user_id: social_service_user_id))
      end

      user
    end
  end
end
