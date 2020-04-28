class UserChannel < ApplicationCable::Channel
  def subscribed
    super_user = User.find(params[:user_id])

    Rails.logger.debug("UserChannel user: #{super_user.id} subscribed")
    stream_for super_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
