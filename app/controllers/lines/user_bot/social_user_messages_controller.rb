# frozen_string_literal: true

class Lines::UserBot::SocialUserMessagesController < Lines::UserBotDashboardController
  def new
  end

  def create
    outcome = SocialUserMessages::Create.run(
      social_user: current_user.social_user,
      content: params["content"],
      readed: false,
      message_type: SocialUserMessage.message_types[:user]
    )

    return_json_response(outcome)
  end
end
