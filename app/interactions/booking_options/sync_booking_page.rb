class BookingOptions::SyncBookingPage < ActiveInteraction::Base
  object :booking_option

  def execute
    booking_page = BookingPage.joins(:booking_options).where(booking_options: { id: booking_option.id }, rich_menu_only: true).take

    if booking_page.present?
      booking_page.update(
        title: booking_option.name,
        name: booking_option.name,
        greeting: booking_option.memo.presence || I18n.t("user_bot.dashboards.booking_page_creation.default_greeting", name: booking_option.present_name),
        note: booking_option.memo.presence
      )
    end
  end
end
