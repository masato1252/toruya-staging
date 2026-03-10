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
            if user.social_user && Rails.env.production?
              dashboard_menu = SocialRichMenu.find_by(social_name: UserBotLines::RichMenus::Dashboard::KEY, locale: user.social_user.locale)
              RichMenus::Connect.run(social_target: user.social_user, social_rich_menu: dashboard_menu) if dashboard_menu
            end
          rescue => e
            Rails.logger.error "[StaffAccounts::ConnectUser] Rich menu switch failed for user##{user.id}: #{e.message}"
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
