# frozen_string_literal: true

module StaffAccounts
  class CreateUser < ActiveInteraction::Base
    string :token

    def execute
      staff_account = StaffAccount.find_by(token: token)

      if staff_account && !staff_account.user

        password = Devise.friendly_token
        raw, enc = Devise.token_generator.generate(User, :reset_password_token)

        if Rails.env.development?
          password = "password123"
        end

        user = User.create(
          email: staff_account.email,
          password: password,
          password_confirmation: password,
          confirmed_at: Time.now,
          reset_password_token: enc,
          reset_password_sent_at: Time.now
        )

        if user.valid?
          staff_account.user = user
          staff_account.mark_active
          staff_account.save
        else
          errors.add(:base, "email is invalid for user creation.")
        end
      elsif staff_account && staff_account.user
        staff_account.mark_active
        staff_account.save
      else
        errors.add(:base, "token was invalid")
      end
    end
  end
end

