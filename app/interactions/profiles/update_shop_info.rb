module Profiles
  class UpdateShopInfo < ActiveInteraction::Base
    object :user
    object :social_user
    hash :params do
      string :zip_code
      string :region
      string :city
      string :street1, default: nil
      string :street2, default: nil
    end

    def execute
      ApplicationRecord.transaction do
        user.profile.update!(params.merge!(address: "#{params[:region]}#{params[:city]}#{params[:street1]}#{params[:street2]}"))
        # XXX: The user and social_user was connected, what I want to do is change_rich_menu here
        compose(SocialUsers::Connect, user: user, social_user: social_user, change_rich_menu: true)
      end
    end
  end
end
