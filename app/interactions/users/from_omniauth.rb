module Users
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash

    def execute
      user = User.find_by(email: auth.info.email) ||
        AccessProvider.where(provider: auth[:provider], uid: auth[:uid]).first.try(:user) ||
        User.where(email: auth.info.email).build

      user.email = auth.info.email.presence || user.email
      user.password = Devise.friendly_token[0,20] if user.encrypted_password.blank?
      user.skip_confirmation!
      user.skip_confirmation_notification!

      compose(GoogleOauth::Create, user: user, auth: auth)
      user.save!
      user
    end
  end
end
