# frozen_string_literal: true

class VisitImprovementJob < ApplicationJob
  queue_as :low_priority

  def perform(ahoy_visit)
    case ahoy_visit.landing_page
    when /booking_pages\/(\w+)/
      booking_page_slug = $1

      if booking_page = BookingPage.find_by(slug: booking_page_slug) || BookingPage.find_by(id: booking_page_slug)
        ahoy_visit.update_columns(owner_id: booking_page.user_id, product_id: booking_page.id, product_type: "BookingPage")
      end
    when /sale_pages\/(\w+)/
      sale_page_slug = $1

      if sale_page = SalePage.find_by(slug: sale_page_slug)
        ahoy_visit.update_columns(owner_id: sale_page.user_id, product_id: sale_page.id, product_type: "SalePage")
      end
    when /online_services\/(\w+)/
      online_service_slug = $1

      if online_service = OnlineService.find_by(slug: online_service_slug)
        ahoy_visit.update_columns(owner_id: online_service.user_id, product_id: online_service.id, product_type: "OnlineService")
      end
    end
  end
end
