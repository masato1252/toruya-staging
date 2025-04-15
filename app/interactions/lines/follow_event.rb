# frozen_string_literal: true

require "line_client"

class Lines::FollowEvent < ActiveInteraction::Base
  hash :event, strip: false
  object :social_customer

  def execute
    # Don't send follow message
    # https://toruya.slack.com/archives/C0201K35WMC/p1646709948010259?thread_ts=1646709569.318589&cid=C0201K35WMC
    # LineClient.send(social_customer, I18n.t("line.bot.thanks_follow"))
    if !social_customer.customer && !social_customer.user.line_contact_customer_name_required
      if social_customer.social_user_name.blank?
        LineProfileJob.perform_now(social_customer)
      end

      customer = compose(
        Customers::Create,
        user: social_customer.user,
        customer_last_name: "",
        customer_first_name: social_customer.social_user_name
      )
      social_customer.update!(customer_id: customer.id)
    end
  end
end
