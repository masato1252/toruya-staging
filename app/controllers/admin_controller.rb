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
      {
        label: "Booking Page (#{ApplicationController.helpers.link_to(booking_page.id, Rails.application.routes.url_helpers.booking_page_url(booking_page))}) created".html_safe,
        time: booking_page.created_at
      }
    end
    sale_pages = SalePage.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |sale_page|
      {
        label: "Sale page (#{ApplicationController.helpers.link_to(sale_page.id, Rails.application.routes.url_helpers.sale_page_url(sale_page.slug))}) created".html_safe,
        time: sale_page.created_at
      }
    end
    reservations = Reservation.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |reservation|
      {
        label: "Reservation (#{reservation.id}) created",
        time: reservation.created_at
      }
    end
    customers = Customer.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |customer|
      {
        label: "Customer (#{customer.id}) created",
        time: customer.created_at
      }
    end
    services = OnlineService.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |service|
      {
        label: "OnlineService created",
        time: service.created_at
      }
    end
    broadcasts = Broadcast.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |broadcast|
      {
        label: "Broadcast created",
        time: broadcast.created_at
      }
    end
    booking_options = BookingOption.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |booking_option|
      {
        label: "Booking Price created",
        time: booking_option.created_at
      }
    end
    personal_schedules = CustomSchedule.closed.where(user_id: user.id).where("created_at > ?", 1.months.ago).map do |custom_schedule|
      {
        label: "Personal Schedule created",
        time: custom_schedule.created_at
      }
    end

    customer_messages = SocialMessage.where(social_account: social_account).where(message_type: [:customer, :customer_reply_bot]).where("created_at > ?", 1.months.ago).map do |message|
      {
        label: "Customer Message created",
        time: message.created_at
      }
    end
    user_messages = SocialMessage.where(social_account: social_account).where(message_type: [:staff]).where("created_at > ?", 1.months.ago).map do |message|
      {
        label: "User Message created",
        time: message.created_at
      }
    end

    @logs = [
      booking_pages,
      customer_messages,
      user_messages,
      sale_pages,
      reservations,
      customers,
      services,
      broadcasts,
      booking_options
    ].flatten.compact.sort_by {|event| event[:time] }
  end
end
