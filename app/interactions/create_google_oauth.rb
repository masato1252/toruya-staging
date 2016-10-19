class CreateGoogleOauth < ActiveInteraction::Base
  object :user, class: User
  object :auth, class: OmniAuth::AuthHash

  def execute
    data = auth.info

    access = user.access_provider || user.build_access_provider
    access.provider = auth.provider
    access.uid = auth.uid
    access.access_token = auth.credentials.token
    access.refresh_token = auth.credentials.refresh_token
    access.save

    access
  end
end
