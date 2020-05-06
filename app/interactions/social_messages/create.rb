require "line_client"

module SocialMessages
  class Create < ActiveInteraction::Base
    object :social_customer
    object :staff, default: nil
    string :content
    boolean :readed

    def execute
      message = SocialMessage.create(
        social_account: social_customer.social_account,
        social_customer: social_customer,
        staff: staff,
        raw_content: content,
        readed_at: readed ? Time.zone.now : nil
      )

      if message.errors.present?
        errors.merge!(message.errors)
      elsif staff.nil?
        UserChannel.broadcast_to(
          social_customer.user,
          {
            type: "customer_new_message",
            data: {
              customer_id: social_customer.social_user_id,
              message: MessageSerializer.new(message).serializable_hash[:data][:attributes]
            }
          }
        )
      elsif staff
        LineClient.send(social_customer, content) unless Rails.env.development?
      end

      message
    end
  end
end
