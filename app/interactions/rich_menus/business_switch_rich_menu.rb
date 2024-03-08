# frozen_string_literal: true

require "line_client"

module RichMenus
  class BusinessSwitchRichMenu < ActiveInteraction::Base
    object :owner, class: User

    def execute
      if owner.social_user
        owner.owner_staff_accounts.each do |staff_account|
          if staff_account.user&.social_user
            UserBotLines::Actions::SwitchRichMenu.run(social_user: staff_account.user.social_user)
          end
        end
      end
    end
  end
end
