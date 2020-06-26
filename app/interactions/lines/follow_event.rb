require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
    LineClient.flex(
      social_customer,
      LineMessages::FlexTemplateContainer.template(
        altText: I18n.t("line.bot.thanks_follow.body1"),
        contents: LineMessages::FlexTemplateContent.content3(
          body1: I18n.t("line.bot.thanks_follow.body1"),
          body2: I18n.t("line.bot.thanks_follow.body2")
        )
      )
    )
    Lines::FeaturesButton.run(social_customer: social_customer)
  end
end
