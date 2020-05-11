class UserChannel < ApplicationCable::Channel
  def subscribed
    @super_user = User.find(params[:user_id])

    Rails.logger.debug("===UserChannel user: #{@super_user.id} subscribed")
    stream_for @super_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.debug("===UserChannel user: #{@super_user.id} unsubscribed")
    stop_all_streams
  end

  def send_message(data)
    # TODO: Change to SocialMessages::Create.perform_later when we had real in time background runner
    SocialMessages::Create.run!(
      social_customer: SocialCustomer.find_by!(social_user_id: data["customer_id"]),
      staff: staff,
      content: data["text"],
      readed: true
    )
  end

  def get_messages(data)
    social_messages =
      SocialMessage
      .includes(:social_customer)
      .where(social_customers: { social_user_id: data["customer_id"] })
      .where("social_messages.created_at < ?", data["oldest_message_at"] ? Date.parse(data["oldest_message_at"]) : Time.now)
      .order("social_messages.created_at DESC")
      .limit(50)

    _messages = social_messages.map { |message| MessageSerializer.new(message).serializable_hash[:data][:attributes] }
    _messages.reverse!

    UserChannel.broadcast_to(@super_user, { type: "prepend_messages", data: { customer_id: data['customer_id'], messages: _messages }.as_json })
  end

  def get_customers(data)
    social_customers = SocialAccount
      .find_by!(channel_id: data["channel_id"], user_id: @super_user.id)
      .social_customers.includes(:social_messages)
      .order("created_at ASC")

    _customers = social_customers.map { |customer| CustomerSerializer.new(customer).serializable_hash[:data][:attributes] }
    Rails.logger.debug("===#{_customers}")

    UserChannel.broadcast_to(@super_user, { type: "append_customers", data: { channel_id: data["channel_id"], customers: _customers }.as_json })
  end

  def staff
    @staff ||= current_user.current_staff(@super_user)
  end
end
