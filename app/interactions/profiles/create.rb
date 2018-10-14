module Profiles
  class Create < ActiveInteraction::Base
    object :user, class_name: "User"
    hash :params do
      string :last_name
      string :first_name
      string :phonetic_last_name
      string :phonetic_first_name
      string :address
      string :phone_number
      string :zip_code
    end

    def execute
      user.transaction do
        profile = user.build_profile(params)
        profile.save

        if profile.new_record?
          errors.merge!(profile.errors)
        else
          compose(Staffs::CreateOwner, user: user)
        end

        profile
      end
    end
  end
end
