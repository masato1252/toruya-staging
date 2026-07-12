# frozen_string_literal: true

class Lines::UserBot::Customers::MessagesController < Lines::UserBotDashboardController
  before_action :set_customer, only: [:index]

  def index
    if compat_read_enabled?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      payload = owner_id && compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/customer/messages",
        {
          customer_id: params[:id],
          oldest_message_at: params[:oldest_message_at],
          oldest_message_id: params[:oldest_message_id]
        }.compact
      )

      if payload
        render json: payload
      else
        render json: { status: "failed", error_message: "メッセージの取得に失敗しました" }, status: :bad_gateway
      end
      return
    end

    render json: SocialMessages::Recent.run!(
      customer: @customer,
      oldest_message_at: params[:oldest_message_at],
      oldest_message_id: params[:oldest_message_id]
    )
  end

  private

  def set_customer
    if compat_read_enabled?
      return
    end

    @customer = Customer.find(params[:id])
  end
end
