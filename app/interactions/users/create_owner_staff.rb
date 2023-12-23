# frozen_string_literal: true

module Users
  class CreateOwnerStaff < ActiveInteraction::Base
    object :owner_user, class: User
    object :user

    def execute
      return if owner_user == user

      ApplicationRecord.transaction do
        staff = user.current_staff(owner_user)

        unless staff
          staff = owner_user.staffs.new
          staff.save
          staff_account = owner_user.owner_staff_accounts.find_or_initialize_by(staff: staff)
          staff_account.token = Digest::SHA1.hexdigest("#{staff_account.id}-#{Time.now.to_i}-#{SecureRandom.random_number}")
          staff_account.owner!
          compose(StaffAccounts::ConnectUser, token: staff_account.token, user: user)
        end
      end
    end
  end
end
