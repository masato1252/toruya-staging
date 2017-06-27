module GoogleOauth
  class Create < ActiveInteraction::Base
    object :user
    object :auth, class: OmniAuth::AuthHash

    def execute
      access = user.access_provider || user.build_access_provider
      access.provider = auth.provider
      access.uid = auth.uid
      access.email = auth.info.email
      access.access_token = auth.credentials.token
      access.refresh_token = auth.credentials.refresh_token

      if access.save
        Customer.where(user: user).delete_all
        ContactGroup.where(user: user).delete_all
      end

      access
    end
  end
end
