require "line_client"

class Lines::Actions::ShopPhone < ActiveInteraction::Base
  object :social_customer

  def execute
    user = social_customer.social_account.user
    message = user.shops.map do |shop|
      "#{shop.display_name}: #{shop.phone_number}"
    end.join("\n")

    LineClient.send(social_customer, message)

    Lines::MessageEvent.run(social_customer: social_customer, event: {})
  end
end
