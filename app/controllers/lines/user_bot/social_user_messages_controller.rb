# frozen_string_literal: true

class Lines::UserBot::SocialUserMessagesController < Lines::UserBotDashboardController
  def create
    outcome = SocialUserMessages::Create.run(
      social_user: current_user.social_user,
      content: params["content"],
      readed: false,
      message_type: SocialUserMessage.message_types[:user]
    )

    render json: json_response(outcome)
  end
end
