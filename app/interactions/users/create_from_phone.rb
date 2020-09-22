module Users
  class CreateFromPhone < ActiveInteraction::Base
    object :social_user
    string :last_name
    string :first_name
    string :phonetic_last_name
    string :phonetic_first_name
    string :phone_number
    string :referral_token, default: nil
    string :email, default: nil

    def execute
      user = User.find_by(phone_number: phone_number) ||
        User.where(phone_number: phone_number).build(password: Devise.friendly_token[0, 20])

      user.skip_confirmation!
      user.skip_confirmation_notification!
      user.referral_token ||= Devise.friendly_token[0,5]

      loop do
        if User.where(referral_token: user.referral_token).where.not(id: user.id).exists?
          user.referral_token = Devise.friendly_token[0,5]
        else
          break
        end
      end


      ApplicationRecord.transaction do
        if user.new_record? &&
            referral_token && (referee = User.find_by(referral_token: referral_token)) &&
            referee.business_member?
          compose(Referrals::Build, referee: referee, referrer: user)
        end
        compose(Users::BuildDefaultData, user: user)
        user.save(validate: false)
        compose(SocialUsers::Connect, user: user, social_user: social_user, change_rich_menu: false)
        compose(Profiles::Create, user: user, params: {
          last_name: last_name,
          first_name: first_name,
          phonetic_last_name: phonetic_last_name,
          phonetic_first_name: phonetic_first_name,
          email: email
        })
        user
      end
    end
  end
end
