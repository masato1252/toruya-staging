module StaffAccounts
  class Create < ActiveInteraction::Base
    object :staff
    object :owner, class: User

    hash :params do
      boolean :enabled
      string :email, default: nil
      string :level
    end

    def execute
      staff_account = owner.owner_staff_accounts.find_or_initialize_by(staff: staff)
      staff_account.email = params[:email]
      staff_account.level = params[:level]

      if params[:enabled]
        unless staff_account.active?
          staff_account.state = :pending
        end
      else
        staff_account.state = :disabled
      end

      if staff_account.email_changed?
        staff_account.user = User.find_by(email: staff_account.email)

        if staff_account.user
          # If Connect Email is the same as one active user, connect user directly, active account if state is not disabled
          staff_account.state = :active unless staff_account.disabled?
        else
          # Otherwise Send Staff Account Connect Email
          staff_account.state = :pending unless staff_account.disabled?
        end
      end

      staff_account.save
    end
  end
end
