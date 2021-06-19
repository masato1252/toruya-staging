require "line_client"

module SocialUserMessages
  class FetchImage < ActiveInteraction::Base
    object :social_user_message

    def execute
      message_body = JSON.parse(social_user_message.raw_content)
      response = LineClient.message_content(social_customer: social_user_message.social_user, message_id: message_body["messageId"])

      tf = Tempfile.open("content", binmode: true)
      tf.write(response.body)
      tf.rewind
      social_user_message.image.attach(io: tf, filename: "img.jpg", content_type: "image/jpg")
    end
  end
end
