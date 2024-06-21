# frozen_string_literal: true

class AdminController < ApplicationController
  include Devise::Controllers::Rememberable
  include ControllerHelpers
  include UserBotCookies

  def as_user
    user = User.find(params[:as_user_id])
    sign_out
    remember_me(user)
    sign_in(user)
    write_user_bot_cookies(:current_user_id, user.id)
    write_user_bot_cookies(:social_service_user_id, user.social_user&.social_service_user_id)

    redirect_to lines_user_bot_settings_path(user.id)
  end

  def logs
    user = User.find_by(id: params[:user_id])
    social_account = user.social_account
    booking_pages = BookingPage.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |booking_page|
      { label: "予約ページ作成 (#{ApplicationController.helpers.link_to(booking_page.id, Rails.application.routes.url_helpers.booking_page_url(booking_page))})".html_safe, time: booking_page.created_at }
    end
    sale_pages = SalePage.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |sale_page|
      { label: "宣伝用LP作成 (#{ApplicationController.helpers.link_to(sale_page.id, Rails.application.routes.url_helpers.sale_page_url(sale_page.slug))})".html_safe, time: sale_page.created_at }
    end
    reservation_ids = Reservation.where(user_id: user.id).where("created_at > ?", 1.months.ago).pluck(:id)
    manual_reservations = ReservationCustomer.where(reservation_id: reservation_ids, booking_page_id: nil).map do |reservation_customer|
      { label: "予約作成", time: reservation_customer.created_at }
    end
    booking_page_reservations = ReservationCustomer.where(reservation_id: reservation_ids).where.not(booking_page_id: nil).map do |reservation_customer|
      { label: "予約ページ予約作成", time: reservation_customer.created_at }
    end
    line_customers = SocialCustomer.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |customer|
      { label: "Line 顧客作成", time: customer.created_at }
    end
    customers = Customer.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |customer|
      { label: "顧客作成(#{customer.id})", time: customer.created_at }
    end
    services = OnlineService.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |service|
      { label: "サービス作成", time: service.created_at }
    end
    broadcasts = Broadcast.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |broadcast|
      { label: "セグメント配信作成", time: broadcast.created_at }
    end
    booking_options = BookingOption.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |booking_option|
      { label: "予約価格作成", time: booking_option.created_at }
    end
    personal_schedules = CustomSchedule.closed.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |custom_schedule|
      { label: "個人の予定作成", time: custom_schedule.created_at }
    end
    menus = Menu.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |menu|
      { label: "メニュー作成", time: menu.created_at }
    end
    customer_messages = SocialMessage.where(social_account: social_account).where(message_type: [:customer]).where("created_at > ?", 1.months.ago).map do |message|
      { label: "メッセージ受信", time: message.created_at }
    end
    user_messages = SocialMessage.where(social_account: social_account).where(message_type: [:staff]).where("created_at > ?", 1.months.ago).map do |message|
      { label: "メッセージ送信", time: message.created_at }
    end

    @logs = [
      booking_pages,
      customer_messages,
      user_messages,
      sale_pages,
      manual_reservations,
      booking_page_reservations,
      line_customers,
      customers,
      services,
      broadcasts,
      booking_options,
      personal_schedules,
      menus
    ].flatten.compact.sort_by {|event| event[:time] }
  end
end
