require "line_client"

module SocialMessages
  class FetchImage < ActiveInteraction::Base
    object :social_message

    def execute
      message_body = JSON.parse(social_message.raw_content)
      response = LineClient.message_content(social_customer: social_message.social_customer, message_id: message_body["messageId"])

      tf = Tempfile.open("content", binmode: true)
      tf.write(response.body)
      tf.rewind
      social_message.image.attach(io: tf, filename: "img.jpg", content_type: "image/jpg")
      tf.close
    end
  end
end
