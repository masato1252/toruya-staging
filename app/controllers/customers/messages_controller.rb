# frozen_string_literal: true

class Customers::MessagesController < DashboardController
  MESSAGES_PER_PAGE = 50
  before_action :set_customer, only: [:index]

  def index
    render json: { messages: [] } unless @customer.social_customer

    scope = SocialMessage.includes(:social_customer).where(social_customers: { social_user_id: @customer.social_customer.social_user_id })
    social_messages =
      scope
      .where(
        "social_messages.created_at < :oldest_message_at OR
        (social_messages.created_at = :oldest_message_at AND social_messages.id < :oldest_message_id)",
        oldest_message_at: Time.current,
        oldest_message_id: INTEGER_MAX)
      .order("social_messages.created_at DESC, social_messages.id DESC")
      .limit(MESSAGES_PER_PAGE + 1)

    scope.where(readed_at: nil).update_all(readed_at: Time.current)

    _messages = social_messages[0...MESSAGES_PER_PAGE].map { |message| MessageSerializer.new(message).attributes_hash }
    _messages.reverse!

    render json: { messages: _messages }
  end

  private

  def set_customer
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
  end
end
