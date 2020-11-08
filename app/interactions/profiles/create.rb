module Profiles
  class Create < ActiveInteraction::Base
    object :user
    hash :params do
      string :last_name
      string :first_name
      string :phonetic_last_name
      string :phonetic_first_name
      string :address, default: nil
      string :phone_number, default: nil
      string :email, default: nil
      string :zip_code, default: nil
    end

    def execute
      user.transaction do
        profile = user.build_profile(params)
        profile.save

        if profile.new_record?
          errors.merge!(profile.errors)
        else
          compose(Staffs::CreateOwner, user: user)

          if user.reference
            Notifiers::Notifications::NewReferrer.perform_later(
              receiver: user.reference.referee,
              user: user.reference.referee
            )
          end
        end

        profile
      end
    end
  end
end
