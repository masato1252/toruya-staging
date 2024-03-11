# frozen_string_literal: true

module StaffAccounts
  class ConnectUser < ActiveInteraction::Base
    string :token
    object :user

    def execute
      staff_account = StaffAccount.find_by(token: token)

      if staff_account
        staff_account.user = user
        staff_account.mark_active

        if staff_account.save
          staff = staff_account.staff

          staff.update(
            last_name: staff.last_name.presence || user.profile.last_name,
            first_name: staff.first_name.presence || user.profile.first_name,
            phonetic_last_name: staff.phonetic_last_name.presence || user.profile.phonetic_last_name,
            phonetic_first_name: staff.phonetic_first_name.presence || user.profile.phonetic_first_name
          )

          Notifiers::Users::Notifications::StaffJoined.run(receiver: staff_account.owner)
        else
          errors.merge!(staff_account.errors)
        end

        staff_account
      end
    end
  end
end
