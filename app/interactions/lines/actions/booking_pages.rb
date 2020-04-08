require "line_client"

class Lines::Actions::BookingPages < ActiveInteraction::Base
  object :social_customer

  # {
  #   "type": "template",
  #   "altText": "this is a carousel template",
  #   "template": {
  #     "type": "carousel",
  #     "columns": [
  #       {
  #         "title": "this is menu",
  #         "text": "description",
  #         "defaultAction": {
  #           "type": "uri",
  #           "label": "View detail",
  #           "uri": "http://example.com/page/123"
  #         },
  #         "actions": [
  #           {
  #             "type": "postback",
  #             "label": "Buy",
  #             "data": "action=buy&itemid=111"
  #           },
  #         ]
  #       },
  #       {
  #         "title": "this is menu",
  #         "text": "description",
  #         "defaultAction": {
  #           "type": "uri",
  #           "label": "View detail",
  #           "uri": "http://example.com/page/222"
  #         },
  #         "actions": [
  #           {
  #             "type": "postback",
  #             "label": "Buy",
  #             "data": "action=buy&itemid=222"
  #           },
  #         ]
  #       }
  #     ],
  #   }
  # }

  def execute
    user = social_customer.social_account.user
    # XXX: refactor to better query
    columns = user.booking_pages.where(draft: false).started.map do |booking_page|
      if booking_page.started? && !booking_page.ended?
        {
          "title": booking_page.title,
          "text": booking_page.title,
          "defaultAction": {
            "type": "uri",
            "label": "View detail",
            "uri": Rails.application.routes.url_helpers.booking_page_url(booking_page)
          },
          "actions": [
            {
              "type": "uri",
              "label": "View detail",
              "uri": Rails.application.routes.url_helpers.booking_page_url(booking_page)
            }
          ]
        }
      end
    end.compact.first(10)

    # handle 400 error back
    if columns.blank?
      LineClient.send(social_customer, "Sorry, we don't have any activites now")
    else
      LineClient.carousel_template( social_customer: social_customer, title: "Booking pages", text: "There are our active booking activities", columns: columns)
    end

    Lines::MessageEvent.run(social_customer: social_customer, event: {})
  end
end
