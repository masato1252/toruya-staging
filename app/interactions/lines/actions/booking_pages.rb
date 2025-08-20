# frozen_string_literal: true

require "line_client"

class Lines::Actions::BookingPages < ActiveInteraction::Base
  LINE_COLUMNS_NUMBER_LIMIT = 10

  object :social_customer
  integer :function_access_id, default: nil

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
    contents = user.line_keyword_booking_pages.map do |booking_page|
      if booking_page.started? && !booking_page.ended? && !booking_page.draft && booking_page.deleted_at.nil? && !booking_page.rich_menu_only
        ::LineMessages::FlexTemplateContent.two_header_card(
          title1: booking_page.title,
          title2: (booking_page.greeting.presence || booking_page.note.presence || booking_page.title).first(100),
          action_templates: [
            LineActions::Uri.new(
              action: "book",
              url: Rails.application.routes.url_helpers.booking_page_url(booking_page.slug, social_user_id: social_customer.social_user_id, _from: "customer_bot", function_access_id: function_access_id),
              btn: "primary"
            )
          ].map(&:template)
        )
      end
    end.compact.first(LINE_COLUMNS_NUMBER_LIMIT)

    # handle 400 error back
    if contents.blank?
      compose(
        SocialMessages::Create,
        social_customer: social_customer,
        content: I18n.t("line.bot.messages.booking_pages.no_available_pages"),
        readed: true,
        message_type: SocialMessage.message_types[:bot]
      )
    else
      line_response = LineClient.flex(
        social_customer,
        ::LineMessages::FlexTemplateContainer.carousel_template(
          altText: I18n.t("line.bot.messages.booking_pages.available_pages"),
          contents: contents
        )
      )

      if line_response.is_a?(Net::HTTPOK)
        compose(
          SocialMessages::Create,
          social_customer: social_customer,
          content: I18n.t("line.bot.messages.booking_pages.available_pages"),
          readed: true,
          message_type: SocialMessage.message_types[:bot],
          send_line: false
        )
      end
    end
  end
end
