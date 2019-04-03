module StaffAccounts
  class Create < ActiveInteraction::Base
    object :staff
    boolean :resend, default: false

    hash :params do
      string :email, default: nil
      string :level, default: "employee"
    end

    validate :validate_unique_user

    def execute
      staff_account = owner.owner_staff_accounts.find_or_initialize_by(staff: staff)
      staff_account.email = params[:email]
      staff_account.level = params[:level]

      if staff_account.persisted?
        # owner level could not change
        if (staff_account.level_was == "owner" && staff_account.level != "owner") ||
            (staff_account.level_was != "owner" && staff_account.level == "owner")
          errors.add(:level, "You could not change owner level")
          return
        end
      end

      staff_account.mark_pending unless staff_account.active?

      if resend || staff_account.email_changed?
        staff_account.user = User.find_by(email: staff_account.email)

        # Owner staff account only be created after user login, so it is definitely active
        if staff_account.owner?
          staff_account.mark_active
        else
          staff_account.mark_pending unless staff_account.disabled?

          staff_account.token = Digest::SHA1.hexdigest("#{staff_account.id}-#{Time.now.to_i}-#{SecureRandom.random_number}")

          if staff_account.save
            NotificationMailer.activate_staff_account(staff_account).deliver_now if staff_account.email.present?
          end
        end
      end

      if staff_account.changes.present?
        if staff_account.save
          staff_account
        else
          errors.merge!(staff_account.errors)
        end
      end
    end

    private

    def validate_unique_user
      if owner.owner_staff_accounts.where(email: params[:email], active_uniqueness: true).where.not(staff_id: staff.id).exists?
        errors.add(:staff, :email_uniqueness_required)
      end
    end

    def owner
      staff.user
    end
  end
end
