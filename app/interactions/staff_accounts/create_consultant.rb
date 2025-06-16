module StaffAccounts
  class CreateConsultant < ActiveInteraction::Base
    string :token
    object :client, class: User

    def execute
      ApplicationRecord.transaction do
        consultant_user =
          if _consultant_user = User.find_by(referral_token: token)
            _consultant_user
          else
            consultant_account = ConsultantAccount.find_by!(token: token)

            consultant_account.active!
            consultant_account.consultant_user
          end

        staff = compose(Staffs::Invite, user: client, phone_number: consultant_user.phone_number, consultant: true)
        compose(StaffAccounts::ConnectUser, token: staff.staff_account.token, user: consultant_user)
      end
    end
  end
end
