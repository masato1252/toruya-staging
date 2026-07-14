# frozen_string_literal: true

class Lines::UserBot::Reservations::MessagesController < Lines::UserBotDashboardController
  before_action :authorize_reservation

  def new
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      context = compat_fetch_v1_json(
        "/lines/user_bot/owner/#{owner_id}/reservations/#{params[:reservation_id]}/page_context"
      )&.dig("data", "broadcast_form")
      unless context
        redirect_to lines_user_bot_schedules_path(business_owner_id: owner_id),
                    alert: I18n.t("common.fetch_failed_message", default: "予約情報を取得できませんでした")
        return
      end
      @compat_message_form = context
      render :new_compat
    end
  end

  def create
    if compat_read_data_plane?
      owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
      result = compat_v1_post(
        "/lines/user_bot/owner/#{owner_id}/broadcasts",
        {
          content: params[:content],
          query: {
            "filters" => [{
              "field" => "reservation_id",
              "value" => params[:reservation_id].to_i,
              "condition" => "eq"
            }],
            "operator" => "or"
          },
          query_type: "reservation_customers"
        }
      )
      render json: result || { status: "failed", error_message: "配信を作成できませんでした" },
             status: (result&.dig("status") == "successful" ? :ok : :unprocessable_entity)
      return
    end

    broadcast_params = {
      content: params[:content],
      query: {
        "filters" => [{
          "field" => "reservation_id",
          "value" => reservation.id,
          "condition" => "eq"
        }],
        "operator" => "or"
      },
      query_type: "reservation_customers"
    }

    outcome = Broadcasts::Create.run(user: Current.business_owner, params: broadcast_params)

    flash[:success] = "Broadcast create successfully"
    return_json_response(outcome, { redirect_to: lines_user_bot_schedules_path(business_owner_id: reservation.user_id, reservation_id: reservation.id) })
  end


  private

  def reservation
    @reservation ||= Reservation.find(params[:reservation_id])
  end

  def authorize_reservation
    return if compat_read_data_plane?

    authorize! :edit, reservation
  end
end
