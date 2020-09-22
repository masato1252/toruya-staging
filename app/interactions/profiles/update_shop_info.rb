module Profiles
  class UpdateShopInfo < ActiveInteraction::Base
    object :user
    hash :params do
      string :zip_code
      string :region
      string :city
      string :street1, default: nil
      string :street2, default: nil
    end

    def execute
      user.profile.update(params.merge!(address: "#{params[:region]}#{params[:city]}#{params[:street1]}#{params[:street2]}"))
    end
  end
end
