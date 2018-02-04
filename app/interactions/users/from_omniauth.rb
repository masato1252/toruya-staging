module Users
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash

    def execute
      user = (AccessProvider.where(provider: auth[:provider], uid: auth[:uid]).first.try(:user) ||
       User.where(email: auth.info.email).first_or_initialize
      )
      user.email = user.email.presence || auth.info.email
      user.password = Devise.friendly_token[0,20]
      user.skip_confirmation!
      user.skip_confirmation_notification!

      compose(GoogleOauth::Create, user: user, auth: auth)
      user.save!
      user
    end
  end
end
