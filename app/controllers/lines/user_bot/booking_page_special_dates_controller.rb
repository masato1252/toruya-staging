# frozen_string_literal: true

class Lines::UserBot::BookingPageSpecialDatesController < Lines::UserBotDashboardController
  # show action for dynamic modal loading
  def show
    if compat_read_data_plane?
      payload = compat_fetch_v1_json(
        "/lines/user_bot/owner/#{compat_special_date_owner_id}/booking_page_special_dates/#{params[:id]}"
      )&.dig("data")
      return head :not_found unless payload

      return render partial: 'special_date_modal', locals: {
        booking_page_id: payload["booking_page_id"],
        start_time_date_part: payload["start_at_date_part"],
        start_time_time_part: payload["start_at_time_part"],
        end_time_time_part: payload["end_at_time_part"],
        reason: booking_page_special_date_reason(payload["booking_page_id"])
      }
    end

    booking_page_special_date = BookingPageSpecialDate.includes(booking_page: :shop).find(params[:id])

    # Check permission - user must be the owner of the shop
    if booking_page_special_date.booking_page.shop.user_id == Current.business_owner.id
      render partial: 'special_date_modal', locals: {
        booking_page_id: booking_page_special_date.booking_page_id,
        start_time_date_part: booking_page_special_date.start_at_date,
        start_time_time_part: booking_page_special_date.start_at_time,
        end_time_time_part: booking_page_special_date.end_at_time,
        reason: booking_page_special_date.booking_page.title
      }
    else
      head :unprocessable_entity
    end
  end

  def create
    return head :not_found unless compat_read_data_plane?

    render_compat_special_date_result(
      compat_v1_post(
        "/lines/user_bot/owner/#{compat_special_date_owner_id}/booking_page_special_dates",
        compat_special_date_attrs
      ),
      :created
    )
  end

  def update
    return head :not_found unless compat_read_data_plane?

    render_compat_special_date_result(
      compat_v1_put(
        "/lines/user_bot/owner/#{compat_special_date_owner_id}/booking_page_special_dates/#{params[:id]}",
        compat_special_date_attrs
      )
    )
  end

  def destroy
    return head :not_found unless compat_read_data_plane?

    render_compat_special_date_result(
      compat_v1_delete(
        "/lines/user_bot/owner/#{compat_special_date_owner_id}/booking_page_special_dates/#{params[:id]}"
      )
    )
  end

  private

  def compat_special_date_owner_id
    resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
  end

  def compat_special_date_attrs
    permitted = params.permit(
      :booking_page_id,
      :start_at_date_part,
      :start_at_time_part,
      :end_at_date_part,
      :end_at_time_part,
      booking_page_special_date: [
        :booking_page_id,
        :start_at_date_part,
        :start_at_time_part,
        :end_at_date_part,
        :end_at_time_part
      ]
    )
    permitted.to_h.merge(permitted.fetch("booking_page_special_date", {}))
  end

  def render_compat_special_date_result(result, success_status = :ok)
    if result&.dig("status") == "successful"
      render json: result, status: success_status
    else
      render json: result || { status: "failed", error_message: "特別営業日時の更新に失敗しました" },
             status: :unprocessable_entity
    end
  end

  def booking_page_special_date_reason(booking_page_id)
    payload = compat_fetch_v1_json(
      "/lines/user_bot/owner/#{compat_special_date_owner_id}/booking_pages/#{booking_page_id}/page_context"
    )&.dig("data")
    payload&.fetch("title", "").to_s
  end
end
