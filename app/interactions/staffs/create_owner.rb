module Staffs
  class CreateOwner < ActiveInteraction::Base
    object :user

    def execute
      if !user.profile
        errors.add(:profile, "You need to set up your profile first")
        return
      end

      if staff_account = user.current_staff_account(user)
        staff_account.owner! unless staff_account.owner?
        staff_account
      else
        profile = user.profile

        staff = compose(Staffs::Create,
                        user: user,
                        attrs: {
                          first_name: profile.first_name,
                          last_name: profile.last_name,
                          phonetic_first_name: profile.phonetic_first_name,
                          phonetic_last_name: profile.phonetic_last_name,
                          staff_holiday_permission: true,
                          shop_ids: Shop.where(user: user).active.pluck(:id)
                        })

        compose(StaffAccounts::Create,
                staff: staff,
                params: {
                  email: user.email,
                  level: "owner"
                }
               )
      end
    end
  end
end
