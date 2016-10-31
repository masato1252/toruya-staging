class CreateGoogleOauth < ActiveInteraction::Base
  object :user, class: User
  object :auth, class: OmniAuth::AuthHash

  def execute
    data = auth.info

    if user.access_provider && user.access_provider.uid != auth.uid
      user_provider_account_changed = true
    end

    access = user.access_provider || user.build_access_provider
    access.provider = auth.provider
    access.uid = auth.uid
    access.access_token = auth.credentials.token
    access.refresh_token = auth.credentials.refresh_token

    if access.save && user_provider_account_changed
      Customer.where(user: user).delete_all
      ContactGroup.where(user: user).delete_all
    end

    access
  end
end
