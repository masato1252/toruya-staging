class UserChannel < ApplicationCable::Channel
  MESSAGES_PER_PAGE = 50
  INTEGER_MAX = 4611686018427387903

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
    return unless data["customer_id"]

    scope = SocialMessage.includes(:social_customer).where(social_customers: { social_user_id: data["customer_id"] })
    social_messages =
      scope
      .where(
        "social_messages.created_at < :oldest_message_at OR
        (social_messages.created_at = :oldest_message_at AND social_messages.id < :oldest_message_id)",
        oldest_message_at: data["oldest_message_at"] ? Time.parse(data["oldest_message_at"]) : Time.current,
        oldest_message_id: data["oldest_message_id"] || INTEGER_MAX)
      .order("social_messages.created_at DESC, social_messages.id DESC")
      .limit(MESSAGES_PER_PAGE + 1)

    scope.where(readed_at: nil).update_all(readed_at: Time.current)

    _messages = social_messages[0...MESSAGES_PER_PAGE].map { |message| MessageSerializer.new(message).attributes_hash }
    _messages.reverse!

    UserChannel.broadcast_to(@super_user, { type: "prepend_messages", data: { customer_id: data['customer_id'], messages: _messages }.as_json })
    UserChannel.broadcast_to(@super_user, { type: "customer_has_messages", data: { has_more_messages: social_messages.size > MESSAGES_PER_PAGE }.as_json })
  end

  def get_customers(data)
    return unless data["channel_id"]

    social_customers = SocialCustomer
      .includes(:social_messages, :social_account, :customer)
      .where(social_accounts: { channel_id: data["channel_id"], user_id: @super_user.id })
      .order("social_customers.updated_at DESC")

    _customers = social_customers.map { |customer| SocialCustomerSerializer.new(customer).attributes_hash }
    Rails.logger.debug("===#{_customers}")

    UserChannel.broadcast_to(@super_user, { type: "append_customers", data: { channel_id: data["channel_id"], customers: _customers }.as_json })
  end

  def toggle_customer_conversation_state(data)
    customer = SocialCustomer.find_by!(social_user_id: data["customer_id"])
    customer.update_columns(conversation_state: customer.bot? ? :one_on_one : :bot)
  end

  def search_shop_customers(data)
    shop_customers = Customers::Search.run(
      super_user: @super_user,
      current_user_staff: staff,
      keyword: data["keyword"],
      per_page: 1_000
    ).result

    UserChannel.broadcast_to(@super_user, {
      type: "matched_shop_customers",
      data: shop_customers.map { |shop_customer| CustomerSerializer.new(shop_customer).attributes_hash }.as_json
    })
  end

  def connect_customer(data)
    SocialCustomer.find_by!(social_user_id: data["social_customer_id"]).update_columns(customer_id: data["shop_customer_id"])
  end

  def disconnect_customer(data)
    SocialCustomer.find_by!(social_user_id: data["customer_id"]).update_columns(customer_id: nil)
  end

  def staff
    @staff ||= current_user.current_staff(@super_user)
  end
end
