# frozen_string_literal: true

class AdminChannel < ApplicationCable::Channel
  CHANNEL_NAME = "admin_toruya_user"
  MESSAGES_PER_PAGE = 50

  def subscribed
    @super_user = User.find(params[:user_id])

    Rails.logger.debug("===AdminChannel subscribed")
    stream_for CHANNEL_NAME
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    Rails.logger.debug("===AdminChannel unsubscribed")
    stop_all_streams
  end

  def get_messages(data)
    return unless data["customer_id"]

    scope = SocialUserMessage.includes(:social_user).where(social_users: { social_service_user_id: data["customer_id"] })
    social_messages =
      scope
      .where(
        "social_user_messages.created_at < :oldest_message_at OR
        (social_user_messages.created_at = :oldest_message_at AND social_user_messages.id < :oldest_message_id)",
        oldest_message_at: data["oldest_message_at"] ? Time.parse(data["oldest_message_at"]) : Time.current,
        oldest_message_id: data["oldest_message_id"] || INTEGER_MAX)
      .ordered
      .limit(MESSAGES_PER_PAGE + 1)

    scope.where(readed_at: nil).update_all(readed_at: Time.current)

    _messages = social_messages[0...MESSAGES_PER_PAGE].map { |message| SocialUserMessageSerializer.new(message).attributes_hash }
    _messages.reverse!

    AdminChannel.broadcast_to(CHANNEL_NAME, { type: "prepend_messages", data: { customer_id: data['customer_id'], messages: _messages }.as_json })
    AdminChannel.broadcast_to(CHANNEL_NAME, { type: "customer_has_messages", data: { has_more_messages: social_messages.size > MESSAGES_PER_PAGE }.as_json })
  end

  def get_customers(data)
    return unless data["channel_id"]

    social_users = SocialUser
      .where(locale: data["locale"])
      .includes(:social_user_messages, :memos)
      .order("social_users.pinned DESC, social_users.updated_at DESC").limit(20)

    if data['last_updated_at']
      social_users = social_users.where("social_users.updated_at < ?", Time.zone.parse(data['last_updated_at']))
    end

    _users = social_users.map { |user| SocialUserSerializer.new(user).attributes_hash }
    Rails.logger.debug("===users #{_users.size}")

    AdminChannel.broadcast_to(CHANNEL_NAME, { type: "append_customers", data: { channel_id: data["channel_id"], customers: _users }.as_json })
  end

  def search_shop_customers(data)
  end

  def connect_customer(data)
  end

  def disconnect_customer(data)
    user = User.find_by!(id: data["customer_id"])
    user.social_user.update!(user_id: nil)
  end

  def toggle_customer_pin(data)
    social_user = SocialUser.find_by!(social_service_user_id: data["customer_id"])

    change_pinned = !social_user.pinned
    social_user.same_social_user_scope.each do |s_user|
      s_user.update!(pinned: change_pinned)
    end
  end

  def staff
    @staff ||= current_user.current_staff(@super_user)
  end
end
