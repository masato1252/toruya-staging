class CreateGoogleOauth < ActiveInteraction::Base
  object :user, class: User
  object :auth, class: OmniAuth::AuthHash

  def execute
    data = auth.info

    access = AccessProvider.where(provider: auth.provider, uid: auth.uid).first_or_create do |access|
      access.provider = auth.provider
      access.uid = auth.uid
    end

    access.access_token = auth.credentials.token
    access.refresh_token = auth.credentials.refresh_token
    access.user = user
    access.save

    return access
  end
end
