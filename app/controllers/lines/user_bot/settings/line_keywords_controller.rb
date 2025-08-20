# frozen_string_literal: true

class Lines::UserBot::Settings::LineKeywordsController < Lines::UserBotDashboardController
  def edit_booking_pages
    @booking_pages = Current.business_owner.line_keyword_booking_pages.map { |booking_page| { label: booking_page.name, value: booking_page.id, id: booking_page.id } }
    @booking_page_options = Current.business_owner.booking_pages.where(draft: false).started.normal.map { |booking_page| { label: booking_page.name, value: booking_page.id, id: booking_page.id } }
  end

  def upsert_booking_pages
    outcome = BookingPages::LineSharingOrder.run(user: Current.business_owner, booking_page_ids: params[:booking_page_ids])


    flash[:success] = I18n.t("common.update_successfully_message")

    if params[:async]
      return_json_response(outcome)
    else
      return_json_response(outcome, { redirect_to: lines_user_bot_booking_pages_path(business_owner_id: business_owner_id) })
    end
  end

  def edit_booking_options
    @keyword_options = Current.business_owner.line_keyword_booking_options.map { |booking_option| { label: booking_option.name, value: booking_option.id, id: booking_option.id } }
    @booking_options = Current.business_owner.booking_options.active.map do |booking_option|
      { label: booking_option.name, value: booking_option.id, id: booking_option.id }
    end
  end

  def upsert_booking_options
    outcome = BookingOptions::LineSharingOrder.run(user: Current.business_owner, booking_option_ids: params[:option_ids])

    flash[:success] = I18n.t("common.update_successfully_message")

    if params[:async]
      return_json_response(outcome)
    else
      return_json_response(outcome, { redirect_to: lines_user_bot_booking_options_path(business_owner_id: business_owner_id) })
    end
  end
end
