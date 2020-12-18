require "line_client"

class Lines::Actions::BookingPages < ActiveInteraction::Base
  LINE_COLUMNS_NUMBER_LIMIT = 10

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
    contents = user.booking_pages.where(draft: false, line_sharing: true).started.map do |booking_page|
      if booking_page.started? && !booking_page.ended?
        LineMessages::FlexTemplateContent.content4(
          title1: booking_page.title,
          body1: (booking_page.greeting.presence || booking_page.note.presence || booking_page.title),
          action_templates: [
            LineActions::Uri.new(
              action: "book",
              url: Rails.application.routes.url_helpers.booking_page_url(booking_page, social_user_id: social_customer.social_user_id),
              btn: "primary"
            )
          ].map(&:template)
        )
      end
    end.compact.first(LINE_COLUMNS_NUMBER_LIMIT)

    # handle 400 error back
    if contents.blank?
      LineClient.send(social_customer, I18n.t("line.bot.messages.booking_pages.no_available_pages"))
    else
      LineClient.flex(
        social_customer,
        LineMessages::FlexTemplateContainer.carousel_template(
          altText: I18n.t("line.bot.messages.booking_pages.available_pages"),
          contents: contents
        )
      )
    end
  end
end
