require "line_client"

class Lines::FeaturesButton < ActiveInteraction::Base
  IDENTIFY_SHOP_CUSTOMER = "identify_shop_customer".freeze

  ACTIONS = [
    LineMessages::Postback.new(action: Lines::Actions::BookingPages.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::ShopPhone.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::OneOnOne.class_name, enabled: false),
    LineMessages::Postback.new(action: Lines::Actions::IncomingReservations.class_name, enabled: true),
  ].freeze

  ENABLED_ACTIONS = ACTIONS.select(&:enabled).freeze
  ACTION_TYPES = ENABLED_ACTIONS.map(&:action).freeze

  object :social_customer

  def execute
    LineClient.flex(
      social_customer,
      LineMessages::FlexTemplateContainer.template(
        altText: context[:desc],
        contents: LineMessages::FlexTemplateContent.content2(
          title1: context[:title],
          title2: context[:desc],
          action_templates: context[:action_templates]
        )
      )
    )

    SocialMessages::Create.run!(
      social_customer: social_customer,
      content: chatroom_owner_message_content,
      readed: true,
      message_type: SocialMessage.message_types[:bot]
    )
  end

  private

  def context
    if social_customer.customer
      {
        title: I18n.t("line.bot.features.online_booking.title"),
        desc: I18n.t("line.bot.features.online_booking.desc"),
        action_templates: ENABLED_ACTIONS.map(&:template)
      }
    else
      {
        title: I18n.t("line.bot.features.connect_customer.title"),
        desc: I18n.t("line.bot.features.connect_customer.desc"),
        action_templates: guest_actions.map(&:template)
      }
    end
  end

  def chatroom_owner_message_content
    if social_customer.customer
      "These are the services we provide: #{ACTION_TYPES.join(", ")}"
    else
      "Customer try to identify themselves"
    end
  end

  def guest_actions
    [
      LineMessages::Uri.new(
        action: Lines::FeaturesButton::IDENTIFY_SHOP_CUSTOMER,
        url: Rails.application.routes.url_helpers.lines_identify_shop_customer_url(social_user_id: social_customer.social_user_id)
      )
    ]
  end
end
