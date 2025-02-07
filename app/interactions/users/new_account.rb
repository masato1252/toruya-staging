# frozen_string_literal: true

module Users
  class NewAccount < ActiveInteraction::Base
    object :existing_user, class: User

    def execute
      ApplicationRecord.transaction do
        social_user = existing_user.social_user.deep_clone(only: [
          :social_service_user_id,
          :social_user_name,
          :social_user_picture_url,
          :social_rich_menu_key,
          :locale,
          :release_version,
        ])
        social_user.save

        user = User.new(password: Devise.friendly_token[0, 20])
        user.skip_confirmation!
        user.skip_confirmation_notification!
        user.referral_token ||= Devise.friendly_token[0,5]
        user.public_id ||= SecureRandom.uuid

        loop do
          if User.where(referral_token: user.referral_token).where.not(id: user.id).exists?
            user.referral_token = Devise.friendly_token[0,5]
          else
            break
          end
        end

        compose(Users::BuildDefaultData, user: user)
        user.save(validate: false)
        compose(SocialUsers::Connect, user: user, social_user: social_user, change_rich_menu: false)
        compose(Profiles::Create, user: user, params: {
          last_name: existing_user.last_name,
          first_name: existing_user.first_name,
          phonetic_last_name: existing_user.phonetic_last_name,
          phonetic_first_name: existing_user.phonetic_first_name,
          address: existing_user.profile.address,
          phone_number: existing_user.profile.phone_number,
          email: existing_user.profile.email,
          zip_code: existing_user.profile.zip_code
        })

        compose(
          Profiles::UpdateShopInfo,
          user: user,
          social_user: social_user,
          params: {
            company_name: "#{existing_user.company_name} #{social_user.same_social_user_scope.count}",
            company_phone_number: existing_user.phone_number,
            zip_code: existing_user.profile.zip_code,
            region: existing_user.profile.region,
            city: existing_user.profile.city,
            street1: existing_user.profile.street1,
            street2: existing_user.profile.street2
          }
        )

        Notifiers::Users::ExtraNewLineAccount.perform_later(receiver: user)

        user
      end
    end
  end
end
