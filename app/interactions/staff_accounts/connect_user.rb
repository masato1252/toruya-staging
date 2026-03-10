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

          begin
            social = user.social_user
            Rails.logger.info "[StaffAccounts::ConnectUser] Rich menu switch: user##{user.id}, social_user=#{social&.id}, locale=#{social&.locale}, env_production=#{Rails.env.production?}"
            if social && Rails.env.production?
              dashboard_menu = SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY, locale: social.locale)
              Rails.logger.info "[StaffAccounts::ConnectUser] Dashboard menu found=#{dashboard_menu&.id}, social_name=#{dashboard_menu&.social_name}"
              if dashboard_menu
                RichMenus::Connect.run(social_target: social, social_rich_menu: dashboard_menu)
                Rails.logger.info "[StaffAccounts::ConnectUser] Rich menu switch completed for user##{user.id}"
              end
            end
          rescue => e
            Rails.logger.error "[StaffAccounts::ConnectUser] Rich menu switch failed for user##{user.id}: #{e.class} #{e.message}"
          end

          Notifiers::Users::Notifications::StaffJoined.perform_later(receiver: staff_account.owner, staff_name: staff.name)
        else
          errors.merge!(staff_account.errors)
        end

        staff_account
      end
    end
  end
end
