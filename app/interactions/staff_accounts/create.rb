module StaffAccounts
  class Create < ActiveInteraction::Base
    object :staff
    object :owner, class: User

    hash :params do
      string :email, default: nil
      string :level, default: "staff"
    end

    def execute
      staff_account = owner.owner_staff_accounts.find_or_initialize_by(staff: staff)
      staff_account.email = params[:email]
      staff_account.level = params[:level]

      unless staff_account.active?
        staff_account.state = :pending
      end

      if staff_account.email_changed? || (staff_account.email.present? && !staff_account.user) || (staff_account.user && staff_account.pending?)
        staff_account.user = User.find_by(email: staff_account.email)
        staff_account.state = :pending unless staff_account.disabled?
        staff_account.token = Digest::SHA1.hexdigest("#{staff_account.id}-#{Time.now.to_i}-#{SecureRandom.random_number}")

        if staff_account.save
          NotificationMailer.activate_staff_account(staff_account).deliver_now if staff_account.email.present?
        end
      end

      if staff_account.save
        staff_account
      else
        errors.merge!(staff_account.errors)
      end
    end
  end
end
