# frozen_string_literal: true

class Lines::UserBot::SocialUserMessagesController < Lines::UserBotDashboardController
  def new
  end

  def create
    outcome = SocialUserMessages::Create.perform_later(
      social_user: current_user.social_user,
      content: params["content"],
      readed: false,
      message_type: SocialUserMessage.message_types[:user]
    )

    head :ok
  end
end
